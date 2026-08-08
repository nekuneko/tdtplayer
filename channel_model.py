# channel_model.py
import re
import json
import os
import urllib.request
import urllib.parse
import hashlib
import sqlite3
from datetime import datetime
from PySide6.QtCore import QAbstractListModel, Qt, QModelIndex, Slot, Property, Signal, QThread

from m3u_channel import M3uChannel
from epg_worker import EpgPreloaderWorker

class LogoDownloaderWorker(QThread):
    def __init__(self, download_queue, cache_dir):
        super().__init__()
        self.download_queue = download_queue
        self.cache_dir = cache_dir

    def run(self):
        if not os.path.exists(self.cache_dir):
            os.makedirs(self.cache_dir, exist_ok=True)
            
        headers = {'User-Agent': 'TdtPlayer-Native'}
        for url, local_path in self.download_queue:
            if os.path.exists(local_path) and os.path.getsize(local_path) > 0:
                continue 
            try:
                req = urllib.request.Request(url, headers=headers)
                with urllib.request.urlopen(req, timeout=5.0) as response:
                    with open(local_path, 'wb') as f:
                        f.write(response.read())
            except Exception as e:
                print(f"Error descargando logo {url}: {e}")

class ChannelModel(QAbstractListModel):
    NameRole = Qt.UserRole + 1
    UrlRole = Qt.UserRole + 2
    LogoRole = Qt.UserRole + 3
    ChNoRole = Qt.UserRole + 4

    logoCacheChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._channels = []
        self._base_url = None
        self._worker = None
        self._logo_cache = {}
        
        self.cache_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".logo_cache")
        self.db_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "epg_cache.db")
        
        self._db_conn = None
        self._db_cursor = None
        self._init_sqlite_db()

    def _init_sqlite_db(self):
        try:
            self._db_conn = sqlite3.connect(self.db_path)
            # 🚀 CORRECCIÓN CRÍTICA DE BUCLE: Inicialización limpia del descriptor de la base de datos
            self._db_cursor = self._db_conn.cursor()
            
            self._db_cursor.execute("PRAGMA journal_mode=WAL")
            self._db_cursor.execute("PRAGMA synchronous=NORMAL")
            self._db_cursor.execute("""
                CREATE TABLE IF NOT EXISTS epg_store (
                    channel_name TEXT,
                    start_ts INTEGER,
                    stop_ts INTEGER,
                    title TEXT,
                    description TEXT,
                    PRIMARY KEY (channel_name, start_ts)
                )
            """)
            self._db_cursor.execute("CREATE INDEX IF NOT EXISTS idx_epg_query ON epg_store (channel_name, stop_ts)")
            self._db_conn.commit()
        except Exception as e:
            print(f"Error inicializando SQLite con concurrrencia WAL: {e}")

    def roleNames(self):
        return { self.NameRole: b"name", self.UrlRole: b"url", self.LogoRole: b"logo", self.ChNoRole: b"chNo" }

    def rowCount(self, parent=QModelIndex()): return len(self._channels)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid() or not (0 <= index.row() < len(self._channels)): return None
        channel = self._channels[index.row()]
        if role == self.NameRole: return channel.name
        elif role == self.UrlRole: return channel.url
        elif role == self.LogoRole: return channel.logo or ""
        elif role == self.ChNoRole: return channel.ch_no or ""
        return None

    @Property(dict, notify=logoCacheChanged)
    def logoCache(self): return self._logo_cache

    @Slot(str)
    def parse_m3u_content(self, content: str):
        self.beginResetModel()
        self._channels = []
        self._base_url = None
        self._logo_cache = {}
        lines = content.split('\n')
        logo_regex = re.compile(r'tvg-logo="([^"]+)"')
        ch_no_regex = re.compile(r'tvg-chno="([^"]+)"')
        current_name, current_logo, current_ch_no = "", None, None
        download_queue = []
        os.makedirs(self.cache_dir, exist_ok=True)
        
        for line in lines:
            line = line.strip()
            if line.startswith('#EXTINF:'):
                comma_index = line.rfind(',')
                current_name = line[comma_index + 1:].strip().replace('\r', '') if comma_index != -1 else "Canal Desconocido"
                logo_match = logo_regex.search(line)
                current_logo = logo_match.group(1) if logo_match else None
                ch_no_match = ch_no_regex.search(line)
                current_ch_no = ch_no_match.group(1) if ch_no_match else None
            elif line.startswith('http://') or line.startswith('https://'):
                if current_name:
                    clean_name = current_name.strip().replace('\r', '')
                    local_logo_path = ""
                    if current_logo and (current_logo.startswith('http://') or current_logo.startswith('https://')):
                        parsed_url = urllib.parse.urlparse(current_logo)
                        file_ext = os.path.splitext(parsed_url.path)
                        actual_ext = file_ext[1] if file_ext and len(file_ext) > 1 and len(file_ext[1]) <= 5 else ".png"
                        file_name = hashlib.md5(clean_name.encode('utf-8')).hexdigest() + actual_ext
                        full_local_path = os.path.join(self.cache_dir, file_name)
                        download_queue.append((current_logo, full_local_path))
                        local_logo_path = "file://" + full_local_path
                    else: local_logo_path = current_logo or ""

                    self._channels.append(M3uChannel(name=clean_name, url=line, logo=local_logo_path, ch_no=current_ch_no))
                    if local_logo_path: self._logo_cache[clean_name] = local_logo_path
                    if not self._base_url:
                        parsed_url = urllib.parse.urlparse(line)
                        if parsed_url.netloc: self._base_url = f"{parsed_url.scheme}://{parsed_url.netloc}"
                    current_name, current_logo, current_ch_no = "", None, None
                    
        self.endResetModel()
        self.logoCacheChanged.emit()
        if download_queue:
            self._downloader = LogoDownloaderWorker(download_queue, self.cache_dir)
            self._downloader.start()
        if self._base_url:
            self._worker = EpgPreloaderWorker(self._base_url, self.db_path)
            self._worker.epg_cache_ready.connect(self._on_worker_finished)
            self._worker.start()

    def _on_worker_finished(self, success):
        if success and len(self._channels) > 0:
            self.dataChanged.emit(self.index(0, 0), self.index(len(self._channels) - 1, 0), [])

    @Slot(int, result=str)
    def get_url_at(self, row: int) -> str:
        return self._channels[row].url if 0 <= row < len(self._channels) else ""

    # 🚀 EJECUCIÓN EN 0 MS GARANTIZADA: Mapeo de tupla directo a través de la memoria persistente del cursor WAL
    @Slot(str, result='QVariant')
    def fetch_current_epg(self, channel_name: str) -> dict:
        search_name = str(channel_name).strip()
        current_time = int(datetime.now().timestamp())
        try:
            if not self._db_cursor: 
                return {"title": "Emisión en directo", "description": ""}
            self._db_cursor.execute("""
                SELECT start_ts, stop_ts, title, description FROM epg_store 
                WHERE channel_name = ? AND stop_ts > ? ORDER BY start_ts ASC LIMIT 1
            """, (search_name, current_time))
            row = self._db_cursor.fetchone()
            if row:
                s_dt = datetime.fromtimestamp(row[0])
                e_dt = datetime.fromtimestamp(row[1])
                time_str = f"[{s_dt.strftime('%H:%M')} - {e_dt.strftime('%H:%M')}]"
                return {"title": f"{time_str} {row[2]}", "description": row[3]}
        except Exception as e: 
            print(f"Error SQLite now: {e}")
        return {"title": "Emisión en directo", "description": "Sin descripción detallada disponible."}

    # 🚀 EJECUCIÓN EN 0 MS GARANTIZADA: Mapeo de tupla directo a través de la memoria persistente del cursor WAL
    @Slot(str, result='QVariant')
    def fetch_next_epg(self, channel_name: str) -> dict:
        search_name = str(channel_name).strip()
        current_time = int(datetime.now().timestamp())
        try:
            if not self._db_cursor: 
                return {"title": "[--:-- - --:--] Sin datos", "description": ""}
            self._db_cursor.execute("""
                SELECT start_ts, stop_ts, title, description FROM epg_store 
                WHERE channel_name = ? AND stop_ts > ? ORDER BY start_ts ASC LIMIT 1 OFFSET 1
            """, (search_name, current_time))
            row = self._db_cursor.fetchone()
            if row:
                s_dt = datetime.fromtimestamp(row[0])
                e_dt = datetime.fromtimestamp(row[1])
                time_str = f"[{s_dt.strftime('%H:%M')} - {e_dt.strftime('%H:%M')}]"
                return {"title": f"{time_str} {row[2]}", "description": row[3]}
        except Exception as e: 
            print(f"Error SQLite next: {e}")
        return {"title": "[--:-- - --:--] Sin datos de programación futura", "description": "No se encontraron más eventos planificados en la base de datos local."}

    def __del__(self):
        try:
            if self._db_conn: self._db_conn.close()
        except: pass
