# logo_downloader.py

import os
import urllib.error
import urllib.request

from PySide6.QtCore import QThread


class LogoDownloaderWorker(QThread):
    def __init__(self, download_queue: list, cache_dir: str):
        super().__init__()
        self.download_queue = download_queue
        self.cache_dir = cache_dir

    def run(self) -> None:
        if not os.path.exists(self.cache_dir):
            os.makedirs(self.cache_dir, exist_ok=True)

        headers = {"User-Agent": "TdtPlayer-Native"}

        for url, local_path in self.download_queue:
            if os.path.exists(local_path) and os.path.getsize(local_path) > 0:
                continue

            try:
                req = urllib.request.Request(url, headers=headers)

                # 🚀 SINTAXIS MODERNA:
                # Combinación de múltiples contextos en una sola línea limpia.
                with (
                    urllib.request.urlopen(req, timeout=5.0) as response,
                    open(local_path, "wb") as f,
                ):
                    f.write(response.read())

            except urllib.error.HTTPError as http_err:
                print(
                    f"[LogoWorker] Código de error HTTP "
                    f"{http_err.code} para la URL: {url}"
                )

            except urllib.error.URLError as net_err:
                print(
                    f"[LogoWorker] Fallo de red o timeout al descargar "
                    f"el logo: {net_err.reason}"
                )

            # 🚀 SUSTITUCIÓN DE ALIAS:
            # Reemplazo estricto de IOError por la excepción integrada OSError.
            except OSError as os_err:
                print(
                    f"[LogoWorker] Error de sistema o escritura en disco "
                    f"en {local_path}: {os_err}"
                )
