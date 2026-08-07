# channel_model.py
import re
import json
import urllib.request
import urllib.parse
from datetime import datetime
from PySide6.QtCore import QAbstractListModel, Qt, QModelIndex, Slot

from m3u_channel import M3uChannel
from epg_worker import EpgPreloaderWorker

class ChannelModel(QAbstractListModel):
    NameRole = Qt.UserRole + 1
    UrlRole = Qt.UserRole + 2
    LogoRole = Qt.UserRole + 3
    ChNoRole = Qt.UserRole + 4

    def __init__(self, parent=None):
        super().__init__(parent)
        self._channels = []
        self._base_url = None
        self._epg_cache = {}
        self._worker = None

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

    @Slot(str)
    def parse_m3u_content(self, content: str):
        self.beginResetModel()
        self._channels = []
        self._base_url = None
        
        lines = content.split('\n')
        logo_regex = re.compile(r'tvg-logo="([^"]+)"')
        ch_no_regex = re.compile(r'tvg-chno="([^"]+)"')
        
        current_name = ""
        current_logo = None
        current_ch_no = None
        
        for line in lines:
            line = line.strip()
            if line.startswith('#EXTINF:'):
                comma_index = line.rfind(',')
                current_name = line[comma_index + 1:].strip() if comma_index != -1 else "Canal Desconocido"
                logo_match = logo_regex.search(line)
                current_logo = logo_match.group(1) if logo_match else None
                ch_no_match = ch_no_regex.search(line)
                current_ch_no = ch_no_match.group(1) if ch_no_match else None
                
            elif line.startswith('http://') or line.startswith('https://'):
                if current_name:
                    self._channels.append(M3uChannel(
                        name=current_name, url=line, logo=current_logo, ch_no=current_ch_no
                    ))
                    if not self._base_url:
                        from urllib.parse import urlparse
                        parsed_url = urlparse(line)
                        if parsed_url.netloc:
                            self._base_url = f"{parsed_url.scheme}://{parsed_url.netloc}"
                    current_name, current_logo, current_ch_no = "", None, None
                    
        self.endResetModel()
        
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

    @Slot(str, result=dict)
    def fetch_current_epg(self, channel_name: str) -> dict:
        # 1. Limpiamos espacios en blanco del nombre del canal
        search_name = str(channel_name).strip()
        
        # 2. Si la guía YA está guardada en la memoria RAM, la devolvemos al instante (0 milisegundos)
        if search_name in self._epg_cache:
            return self._epg_cache[search_name]
            
        # 3. Si NO está en la RAM, en lugar de consultar por internet y congelar la pantalla,
        # devolvemos una respuesta provisional inmediata para que la interfaz no sufra micro-parones.
        return {
            "title": "Emisión en directo",
            "description": "Buscando información del evento actual en el flujo de Tvheadend..."
        }

