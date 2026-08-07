# channel_model.py
import re
import json
import os
import urllib.request
import urllib.parse
from datetime import datetime
from PySide6.QtCore import QAbstractListModel, Qt, QModelIndex, Slot, Property, Signal, QThread

from m3u_channel import M3uChannel
from epg_worker import EpgPreloaderWorker

# Hilo secundario para descargar las imágenes en segundo plano sin congelar la app
class LogoDownloaderWorker(QThread):
    def __init__(self, download_queue, cache_dir):
        super().__init__()
        self.download_queue = download_queue
        self.cache_dir = cache_dir

    def run(self):
        # Crear directorio si no existe
        if not os.path.exists(self.cache_dir):
            os.makedirs(self.cache_dir, exist_ok=True)
            
        headers = {'User-Agent': 'TdtPlayer-Native'}
        for url, local_path in self.download_queue:
            if os.path.exists(local_path) and os.path.getsize(local_path) > 0:
                continue # Ya está descargado de sesiones previas
            try:
                req = urllib.request.Request(url, headers=headers)
                with urllib.request.urlopen(req, timeout=5.0) as response:
                    # 🚀 CORRECCIÓN: Estructura de bloque de escritura e indentación limpia
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
        self._epg_cache = {}
        self._worker = None
        self._logo_cache = {}
        
        # Ruta absoluta para almacenar la caché física de imágenes en disco
        self.cache_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".logo_cache")
        self._downloader = None

    def roleNames(self):
        return {
            self.NameRole: b"name",
            self.UrlRole: b"url",
            self.LogoRole: b"logo",
            self.ChNoRole: b"chNo"
        }

    def rowCount(self, parent=QModelIndex()):
        return len(self._channels)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid() or not (0 <= index.row() < len(self._channels)):
            return None
        channel = self._channels[index.row()]
        if role == self.NameRole: return channel.name
        elif role == self.UrlRole: return channel.url
        elif role == self.LogoRole: return channel.logo or ""
        elif role == self.ChNoRole: return channel.ch_no or ""
        return None

    @Property(dict, notify=logoCacheChanged)
    def logoCache(self):
        return self._logo_cache

    @Slot(str)
    def parse_m3u_content(self, content: str):
        self.beginResetModel()
        self._channels = []
        self._base_url = None
        self._logo_cache = {}
        
        lines = content.split('\n')
        logo_regex = re.compile(r'tvg-logo="([^"]+)"')
        ch_no_regex = re.compile(r'tvg-chno="([^"]+)"')
        
        current_name = ""
        current_logo = None
        current_ch_no = None
        
        download_queue = []
        
        # Aseguramos la existencia de la carpeta de caché antes de parsear
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
                        # Generamos un nombre de archivo único basado en el hash del nombre del canal para evitar caracteres raros
                        import hashlib
                        file_ext = os.path.splitext(urllib.parse.urlparse(current_logo).path)[1]
                        if not file_ext or len(file_ext) > 5: 
                            file_ext = ".png" # Extensión por defecto
                        
                        file_name = hashlib.md5(clean_name.encode('utf-8')).hexdigest() + file_ext
                        full_local_path = os.path.join(self.cache_dir, file_name)
                        
                        # Guardamos en la cola de descargas
                        download_queue.append((current_logo, full_local_path))
                        # La URL que le damos a QML es una ruta de archivo local absoluta
                        local_logo_path = "file://" + full_local_path
                    else:
                        local_logo_path = current_logo or ""

                    self._channels.append(M3uChannel(
                        name=clean_name, url=line, logo=local_logo_path, ch_no=current_ch_no
                    ))
                    
                    if local_logo_path:
                        self._logo_cache[clean_name] = local_logo_path

                    if not self._base_url:
                        from urllib.parse import urlparse
                        parsed_url = urlparse(line)
                        if parsed_url.netloc:
                            self._base_url = f"{parsed_url.scheme}://{parsed_url.netloc}"
                    current_name, current_logo, current_ch_no = "", None, None
                    
        self.endResetModel()
        self.logoCacheChanged.emit()
        
        # Lanzamos el hilo secundario para descargar los logos en paralelo
        if download_queue:
            self._downloader = LogoDownloaderWorker(download_queue, self.cache_dir)
            self._downloader.start()
        
        if self._base_url:
            self._worker = EpgPreloaderWorker(self._base_url)
            self._worker.epg_cache_ready.connect(self._on_cache_ready)
            self._worker.start()

    def _on_cache_ready(self, cache_dict):
        self._epg_cache = cache_dict

    @Slot(int, result=str)
    def get_url_at(self, row: int) -> str:
        if 0 <= row < len(self._channels):
            return self._channels[row].url
        return ""

    @Slot(str, result='QVariant')
    def fetch_current_epg(self, channel_name: str) -> dict:
        search_name = str(channel_name).strip()
        if search_name in self._epg_cache:
            return self._epg_cache[search_name]
            
        return {
            "title": "Emisión en directo",
            "description": "Buscando información del evento actual en el flujo de Tvheadend..."
        }
