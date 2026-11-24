# logo_downloader.py

import os
import urllib.error
import urllib.request

from PySide6.QtCore import QThread, Signal


class LogoDownloaderWorker(QThread):
    logo_downloaded = Signal(int)

    def __init__(self, download_queue: list, cache_dir: str):
        super().__init__()
        self.download_queue = download_queue
        self.cache_dir = cache_dir

    def run(self) -> None:
        if not os.path.exists(self.cache_dir):
            os.makedirs(self.cache_dir, exist_ok=True)

        headers = {"User-Agent": "TdtPlayer-Native"}

        for row_idx, url, local_path in self.download_queue:
            if self.isInterruptionRequested():
                break

            if os.path.exists(local_path) and os.path.getsize(local_path) > 0:
                self.logo_downloaded.emit(row_idx)
                continue

            try:
                req = urllib.request.Request(url, headers=headers)

                # 🚀 SINTAXIS MODERNA:
                # Combinación de múltiples contextos en una sola línea limpia.
                with urllib.request.urlopen(req, timeout=2.5) as response:
                    data = response.read()

                if self.isInterruptionRequested():
                    break

                if data:
                    with open(local_path, "wb") as f:
                        f.write(data)
                    self.logo_downloaded.emit(row_idx)

            except urllib.error.HTTPError as http_err:
                if not self.isInterruptionRequested():
                    print(
                        f"[LogoWorker] Código de error HTTP "
                        f"{http_err.code} para la URL: {url}"
                    )

            except urllib.error.URLError as net_err:
                if not self.isInterruptionRequested():
                    print(
                        f"[LogoWorker] Fallo de red o timeout al descargar "
                        f"el logo: {net_err.reason}"
                    )

            # 🚀 SUSTITUCIÓN DE ALIAS:
            # Reemplazo estricto de IOError por la excepción integrada OSError.
            except OSError as os_err:
                if not self.isInterruptionRequested():
                    print(
                        f"[LogoWorker] Error de sistema o escritura en disco "
                        f"en {local_path}: {os_err}"
                    )
