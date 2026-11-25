# hls_proxy.py
import http.server
import re
import socketserver
import ssl
import threading
import time
import urllib.error
import urllib.parse
import urllib.request

_DEFAULT_UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
)
_SSL_CTX = ssl._create_unverified_context()


class _ThreadedHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    allow_reuse_address = True


def _pick_best_variant_pair(master_text: str, base_url: str) -> tuple[str, str] | None:
    """Devuelve (linea_stream_inf, url_variante) con mayor BANDWIDTH."""
    lines = [line.strip() for line in master_text.splitlines() if line.strip()]
    best_bw = -1
    best_pair = None
    for i, line in enumerate(lines):
        if line.startswith("#EXT-X-STREAM-INF:") and i + 1 < len(lines):
            next_line = lines[i + 1]
            if next_line.startswith("#"):
                continue
            bw_match = re.search(r"BANDWIDTH=(\d+)", line)
            bw = int(bw_match.group(1)) if bw_match else 0
            if bw >= best_bw:
                best_bw = bw
                best_pair = (line, urllib.parse.urljoin(base_url, next_line))
    return best_pair


class LocalHlsProxy:
    """Proxy HTTP local en 127.0.0.1 que normaliza URLs, audio separado y Range HLS para Qt FFmpeg."""

    def __init__(self):
        self._server: _ThreadedHTTPServer | None = None
        self._port: int = 0
        self._lock = threading.Lock()
        self._m3u8_cache: dict[str, tuple[float, bytes]] = {}

    def ensure_started(self) -> int:
        with self._lock:
            if self._server is not None:
                return self._port

            proxy_ref = self

            class Handler(http.server.BaseHTTPRequestHandler):
                protocol_version = "HTTP/1.1"

                def log_message(self, _format, *_args):
                    return

                def do_GET(self):
                    parsed = urllib.parse.urlparse(self.path)
                    qs = urllib.parse.parse_qs(parsed.query)
                    target = next(iter(qs.get("u", ())), "")
                    if not target or not target.startswith(("http://", "https://")):
                        self.send_error(400, "Invalid target URL")
                        return

                    try:
                        if parsed.path.endswith(".m3u8"):
                            body = proxy_ref._get_cached_or_fetch_m3u8(target)
                            self.send_response(200)
                            self.send_header("Content-Type", "application/vnd.apple.mpegurl")
                            self.send_header("Content-Length", str(len(body)))
                            self.send_header("Connection", "close")
                            self.end_headers()
                            self.wfile.write(body)
                        else:
                            headers = {"User-Agent": _DEFAULT_UA}
                            range_hdr = self.headers.get("Range")
                            if range_hdr:
                                headers["Range"] = range_hdr

                            req = urllib.request.Request(target, headers=headers)
                            with urllib.request.urlopen(req, timeout=10, context=_SSL_CTX) as resp:
                                status = resp.getcode() or 200
                                self.send_response(status)
                                for hdr in ("Content-Type", "Content-Length", "Content-Range", "Accept-Ranges"):
                                    val = resp.headers.get(hdr)
                                    if val:
                                        self.send_header(hdr, val)
                                self.send_header("Connection", "close")
                                self.end_headers()

                                while True:
                                    chunk = resp.read(65536)
                                    if not chunk:
                                        break
                                    self.wfile.write(chunk)
                    except (ConnectionAbortedError, ConnectionResetError, BrokenPipeError):
                        return
                    except urllib.error.HTTPError as exc:
                        try:
                            self.send_error(exc.code, exc.reason)
                        except OSError:
                            pass
                    except Exception:
                        try:
                            self.send_error(502, "Upstream HLS error")
                        except OSError:
                            pass

            self._server = _ThreadedHTTPServer(("127.0.0.1", 0), Handler)
            _, self._port = self._server.server_address
            thread = threading.Thread(target=self._server.serve_forever, daemon=True)
            thread.start()
            return self._port

    def wrap_url(self, url: str) -> str:
        """Envuelve solo URLs .m3u8; deja intactas las URLs directas (como Tvheadend mpegts)."""
        if not url or ".m3u8" not in url.lower():
            return url
        if url.startswith("http://127.0.0.1:"):
            return url
        port = self.ensure_started()
        encoded = urllib.parse.quote(url, safe="")
        return f"http://127.0.0.1:{port}/playlist.m3u8?u={encoded}"

    def _get_cached_or_fetch_m3u8(self, url: str) -> bytes:
        now = time.monotonic()
        cached = self._m3u8_cache.get(url)
        if cached is not None:
            ts, data = cached
            if (now - ts) < 0.4:
                return data
        try:
            data = self._fetch_and_rewrite_m3u8(url)
            self._m3u8_cache[url] = (now, data)
            if len(self._m3u8_cache) > 64:
                self._m3u8_cache.clear()
            return data
        except Exception:
            if cached is not None:
                _, stale_data = cached
                return stale_data
            raise

    def _rewrite_uri_attr(self, line: str, base_url: str, default_ext: str) -> str:
        port = self._port

        def _repl(match):
            abs_u = urllib.parse.urljoin(base_url, match.group(1))
            enc = urllib.parse.quote(abs_u, safe="")
            ext = ".m3u8" if ".m3u8" in abs_u.lower() else default_ext
            return f'URI="http://127.0.0.1:{port}/sub{ext}?u={enc}"'

        return re.sub(r'URI="([^"]+)"', _repl, line)

    def _fetch_and_rewrite_m3u8(self, url: str, depth: int = 0) -> bytes:
        req = urllib.request.Request(url, headers={"User-Agent": _DEFAULT_UA})
        with urllib.request.urlopen(req, timeout=10, context=_SSL_CTX) as resp:
            final_url = resp.geturl()
            raw_text = resp.read().decode("utf-8", errors="ignore")

        is_master = "#EXT-X-STREAM-INF:" in raw_text
        has_separate_audio = "#EXT-X-MEDIA:" in raw_text and "TYPE=AUDIO" in raw_text

        if is_master and not has_separate_audio and depth < 2:
            best_pair = _pick_best_variant_pair(raw_text, final_url)
            if best_pair:
                _, best_url = best_pair
                return self._fetch_and_rewrite_m3u8(best_url, depth + 1)

        port = self._port
        out_lines: list[str] = []

        if is_master and has_separate_audio:
            for raw_line in raw_text.splitlines():
                line = raw_line.strip()
                if not line:
                    continue
                if line.startswith("#EXTM3U") or line.startswith("#EXT-X-VERSION"):
                    out_lines.append(line)
                elif line.startswith("#EXT-X-MEDIA:"):
                    if "TYPE=AUDIO" in line and "DEFAULT=" not in line:
                        line = line + ",DEFAULT=YES,AUTOSELECT=YES"
                    if 'URI="' in line:
                        out_lines.append(self._rewrite_uri_attr(line, final_url, ".m3u8"))
                    else:
                        out_lines.append(line)
            best_pair = _pick_best_variant_pair(raw_text, final_url)
            if best_pair:
                inf_line, best_url = best_pair
                encoded = urllib.parse.quote(best_url, safe="")
                out_lines.append(inf_line)
                out_lines.append(f"http://127.0.0.1:{port}/playlist.m3u8?u={encoded}")
            return ("\n".join(out_lines) + "\n").encode("utf-8")

        for raw_line in raw_text.splitlines():
            line = raw_line.strip()
            if not line:
                continue
            if line.startswith("#EXT-X-KEY:") and 'URI="' in line:
                out_lines.append(self._rewrite_uri_attr(line, final_url, ".bin"))
            elif line.startswith("#EXT-X-MAP:") and 'URI="' in line:
                out_lines.append(self._rewrite_uri_attr(line, final_url, ".mp4"))
            elif line.startswith("#"):
                out_lines.append(line)
            else:
                abs_url = urllib.parse.urljoin(final_url, line)
                encoded = urllib.parse.quote(abs_url, safe="")
                if is_master or ".m3u8" in abs_url.lower():
                    out_lines.append(f"http://127.0.0.1:{port}/playlist.m3u8?u={encoded}")
                else:
                    out_lines.append(f"http://127.0.0.1:{port}/seg.ts?u={encoded}")

        return ("\n".join(out_lines) + "\n").encode("utf-8")

    def stop(self) -> None:
        with self._lock:
            if self._server is not None:
                self._server.shutdown()
                self._server.server_close()
                self._server = None
