# epg_worker.py

import json
import sqlite3
import urllib.error
import urllib.request
from datetime import datetime, timezone

from PySide6.QtCore import QThread, Signal


class EpgPreloaderWorker(QThread):
    epg_cache_ready = Signal(bool)

    def __init__(self, base_url, db_path):
        super().__init__()
        self.base_url = base_url
        self.db_path = db_path

    def run(self):
        api_url = f"{self.base_url}/api/epg/events/grid?limit=999999"
        headers = {"User-Agent": "TdtPlayer-Preloader"}

        try:
            req = urllib.request.Request(api_url, headers=headers)

            with urllib.request.urlopen(req, timeout=10.0) as response:
                raw_json = json.loads(response.read().decode("utf-8", errors="replace"))

            entries = raw_json.get("entries", [])

            if not entries:
                self.epg_cache_ready.emit(False)
                return

            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()

            cursor.execute("PRAGMA journal_mode=WAL")
            cursor.execute("PRAGMA synchronous=NORMAL")

            # 🚀 CORRECCIÓN DE ZONA HORARIA:
            # Captura consciente mediante objeto timezone.utc.
            current_timestamp = int(datetime.now(timezone.utc).timestamp())

            cursor.execute(
                "DELETE FROM epg_store WHERE stop_ts < ?",
                (current_timestamp,),
            )

            insert_data = []

            for entry in entries:
                ch_name = entry.get("channelName")
                start_ts = entry.get("start", 0)
                stop_ts = entry.get("stop", 0)

                if not ch_name or start_ts == 0 or stop_ts == 0:
                    continue

                clean_ch_name = str(ch_name).strip()
                title = entry.get("title", "Emisión en directo")
                description = (
                    entry.get("description")
                    or entry.get("summary")
                    or "Sin descripción detallada disponible."
                )

                insert_data.append(
                    (
                        clean_ch_name,
                        int(start_ts),
                        int(stop_ts),
                        title,
                        description,
                    )
                )

            cursor.executemany(
                """
                INSERT OR REPLACE INTO epg_store (
                    channel_name,
                    start_ts,
                    stop_ts,
                    title,
                    description
                )
                VALUES (?, ?, ?, ?, ?)
                """,
                insert_data,
            )

            conn.commit()
            conn.close()

            self.epg_cache_ready.emit(True)

        except urllib.error.HTTPError as http_err:
            print(
                f"[Worker] Error HTTP del servidor de Tvheadend "
                f"({http_err.code}): {http_err.reason}"
            )
            self.epg_cache_ready.emit(False)

        except urllib.error.URLError as net_err:
            print(
                f"[Worker] Error de red o timeout al conectar con la API: "
                f"{net_err.reason}"
            )
            self.epg_cache_ready.emit(False)

        except json.JSONDecodeError as json_err:
            print(
                f"[Worker] El JSON devuelto por el servidor remoto está "
                f"corrupto: {json_err.msg} en la línea {json_err.lineno}"
            )
            self.epg_cache_ready.emit(False)

        except sqlite3.Error as sql_err:
            print(
                f"[Worker] Fallo crítico de base de datos en el cursor WAL: {sql_err}"
            )
            self.epg_cache_ready.emit(False)
