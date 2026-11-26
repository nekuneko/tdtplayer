# epg_worker.py
import json
import sqlite3
import urllib.error
import urllib.request
from datetime import datetime, timezone

from PySide6.QtCore import QThread, Signal


class EpgPreloaderWorker(QThread):
    epg_cache_ready = Signal(bool)

    def __init__(self, base_url: str, db_path: str):
        super().__init__()
        self.base_url = base_url
        self.db_path = db_path

    def run(self) -> None:
        api_url = f"{self.base_url}/api/epg/events/grid?limit=999999"
        headers = {"User-Agent": "TdtPlayer-Preloader"}

        try:
            req = urllib.request.Request(api_url, headers=headers)
            with urllib.request.urlopen(req, timeout=10.0) as response:
                raw_json = json.loads(response.read().decode("utf-8", errors="replace"))

            if self.isInterruptionRequested():
                return

            entries = raw_json.get("entries", [])
            if not entries:
                self.epg_cache_ready.emit(False)
                return

            current_timestamp = int(datetime.now(timezone.utc).timestamp())
            insert_data = []

            for entry in entries:
                ch_name = entry.get("channelName")
                start_ts = entry.get("start", 0)
                stop_ts = entry.get("stop", 0)
                if not ch_name or start_ts == 0 or stop_ts == 0:
                    continue

                insert_data.append(
                    (
                        str(ch_name).strip(),
                        int(start_ts),
                        int(stop_ts),
                        entry.get("title", "Emisión en directo"),
                        entry.get("description")
                        or entry.get("summary")
                        or "Sin descripción detallada disponible.",
                    )
                )

            if self.isInterruptionRequested():
                return

            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute("PRAGMA journal_mode=WAL")
                cursor.execute("PRAGMA synchronous=NORMAL")
                cursor.execute("DELETE FROM epg_store WHERE stop_ts < ?", (current_timestamp,))
                cursor.executemany(
                    """
                    INSERT OR REPLACE INTO epg_store (
                        channel_name, start_ts, stop_ts, title, description
                    ) VALUES (?, ?, ?, ?, ?)
                    """,
                    insert_data,
                )
                conn.commit()

            self.epg_cache_ready.emit(True)

        except (urllib.error.HTTPError, urllib.error.URLError, json.JSONDecodeError, sqlite3.Error) as err:
            print(f"[EpgWorker] Error sincronizando EPG: {err}")
            self.epg_cache_ready.emit(False)
