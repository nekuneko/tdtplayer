# epg_worker.py
import urllib.request
import urllib.parse
import json
import sqlite3
import os
from datetime import datetime
from PySide6.QtCore import QThread, Signal

class EpgPreloaderWorker(QThread):
    epg_cache_ready = Signal(bool)

    def __init__(self, base_url, db_path):
        super().__init__()
        self.base_url = base_url
        self.db_path = db_path

    def run(self):
        api_url = f"{self.base_url}/api/epg/events/grid?limit=999999"
        headers = {'User-Agent': 'TdtPlayer-Preloader'}
        
        try:
            req = urllib.request.Request(api_url, headers=headers)
            with urllib.request.urlopen(req, timeout=10.0) as response:
                raw_json = json.loads(response.read().decode('utf-8'))
                entries = raw_json.get("entries", [])
                
                if not entries:
                    self.epg_cache_ready.emit(False)
                    return

                conn = sqlite3.connect(self.db_path)
                cursor = conn.cursor()
                
                # 🚀 ALINEACIÓN DE CONCURRENCIA EN INSERCIÓN: El worker opera en armonía con el lector
                cursor.execute("PRAGMA journal_mode=WAL")
                cursor.execute("PRAGMA synchronous=NORMAL")
                
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS epg_store (
                        channel_name TEXT,
                        start_ts INTEGER,
                        stop_ts INTEGER,
                        title TEXT,
                        description TEXT,
                        PRIMARY KEY (channel_name, start_ts)
                    )
                """)
                cursor.execute("CREATE INDEX IF NOT EXISTS idx_epg_query ON epg_store (channel_name, stop_ts)")
                
                current_timestamp = int(datetime.now().timestamp())
                cursor.execute("DELETE FROM epg_store WHERE stop_ts < ?", (current_timestamp,))
                
                insert_data = []
                for entry in entries:
                    ch_name = entry.get("channelName")
                    start_ts = entry.get("start", 0)
                    stop_ts = entry.get("stop", 0)
                    
                    if not ch_name or start_ts == 0 or stop_ts == 0:
                        continue
                        
                    clean_ch_name = str(ch_name).strip()
                    title = entry.get("title", "Emisión en directo")
                    description = entry.get("description") or entry.get("summary") or "Sin descripción detallada disponible."
                    
                    insert_data.append((clean_ch_name, int(start_ts), int(stop_ts), title, description))
                
                cursor.executemany("""
                    INSERT OR REPLACE INTO epg_store (channel_name, start_ts, stop_ts, title, description)
                    VALUES (?, ?, ?, ?, ?)
                """, insert_data)
                
                conn.commit()
                conn.close()
                
                self.epg_cache_ready.emit(True)
                
        except Exception as e:
            print(f"Error volcando la parrilla en SQLite: {e}")
            self.epg_cache_ready.emit(False)
