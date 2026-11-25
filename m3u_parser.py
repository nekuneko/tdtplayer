# m3u_parser.py
import hashlib
import os
import re
import shutil
import urllib.parse

from PySide6.QtCore import QUrl

from m3u_channel import M3uChannel


class M3uParser:
    LOGO_REGEX = re.compile(r'tvg-logo="([^"]+)"')
    CH_NO_REGEX = re.compile(r'tvg-chno="([^"]+)"')

    def __init__(self, cache_dir: str):
        self.cache_dir = cache_dir
        self.cache_generation = 0

    def clear_cache_dir(self) -> None:
        """Elimina por completo .logo_cache de forma segura en Windows y Linux."""
        if os.path.exists(self.cache_dir):
            shutil.rmtree(self.cache_dir, ignore_errors=True)
        self.cache_generation += 1

    def parse(self, content: str) -> tuple[list[M3uChannel], list[tuple], dict, str | None]:
        """Devuelve (canales, cola_descarga_logos, mapa_logos_existentes, base_url)."""
        channels: list[M3uChannel] = []
        download_queue: list[tuple] = []
        existing_logos: dict[str, str] = {}
        base_url: str | None = None

        os.makedirs(self.cache_dir, exist_ok=True)
        current_name, current_logo, current_ch_no = "", None, None
        next_virtual_chno = 0

        for raw_line in content.split("\n"):
            line = raw_line.strip()
            if line.startswith("#EXTINF:"):
                comma_idx = line.rfind(",")
                current_name = (
                    line[comma_idx + 1 :].strip().replace("\r", "")
                    if comma_idx != -1
                    else "Canal Desconocido"
                )
                logo_m = self.LOGO_REGEX.search(line)
                current_logo = logo_m.group(1) if logo_m else None
                chno_m = self.CH_NO_REGEX.search(line)
                current_ch_no = chno_m.group(1) if chno_m else None

            elif line.startswith(("http://", "https://")) and current_name:
                stream_url = line.split("|", 1)[0].strip() if "|" in line else line
                clean_name = current_name.strip().replace("\r", "")
                local_logo_url = self._resolve_logo(
                    len(channels), clean_name, current_logo, download_queue
                )

                try:
                    suggested_no = int(current_ch_no) if current_ch_no else next_virtual_chno
                except ValueError:
                    suggested_no = next_virtual_chno

                assigned_chno = max(suggested_no, next_virtual_chno)
                next_virtual_chno = assigned_chno + 1

                channels.append(
                    M3uChannel(
                        name=clean_name,
                        url=stream_url,
                        logo=local_logo_url,
                        ch_no=str(assigned_chno),
                    )
                )

                if local_logo_url and os.path.exists(QUrl(local_logo_url).toLocalFile()):
                    existing_logos[clean_name] = local_logo_url

                if not base_url:
                    parsed = urllib.parse.urlparse(stream_url)
                    if parsed.netloc:
                        base_url = f"{parsed.scheme}://{parsed.netloc}"

                current_name, current_logo, current_ch_no = "", None, None


        return channels, download_queue, existing_logos, base_url

    def _resolve_logo(
        self, row_idx: int, clean_name: str, raw_logo: str | None, download_queue: list
    ) -> str:
        if not raw_logo:
            return ""
        if raw_logo.startswith(("http://", "https://")):
            _, ext = os.path.splitext(urllib.parse.urlparse(raw_logo).path)
            valid_ext = ext if ext and 1 < len(ext) <= 5 else ".png"
            file_name = hashlib.md5(clean_name.encode("utf-8")).hexdigest() + valid_ext
            full_path = os.path.join(self.cache_dir, file_name)
            download_queue.append((row_idx, raw_logo, full_path))
            base_url = QUrl.fromLocalFile(full_path).toString()
            return f"{base_url}?v={self.cache_generation}" if self.cache_generation > 0 else base_url
        if os.path.exists(raw_logo):
            return QUrl.fromLocalFile(os.path.abspath(raw_logo)).toString()
        return ""
