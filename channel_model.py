# channel_model.py
import re
from PySide6.QtCore import QAbstractListModel, Qt, QModelIndex, Slot, Property
from m3u_channel import M3uChannel

class ChannelModel(QAbstractListModel):
    # Definimos los roles para que QML pueda leer las propiedades del objeto
    NameRole = Qt.UserRole + 1
    UrlRole = Qt.UserRole + 2
    LogoRole = Qt.UserRole + 3
    ChNoRole = Qt.UserRole + 4

    def __init__(self, parent=None):
        super().__init__(parent)
        self._channels = []

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
        """Algoritmo de parseo equivalente al de Flutter usando RegExp"""
        self.beginResetModel()
        self._channels = []
        
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
                        name=current_name, 
                        url=line, 
                        logo=current_logo, 
                        ch_no=current_ch_no
                    ))
                    current_name = ""
                    current_logo = None
                    current_ch_no = None
                    
        self.endResetModel()

    @Slot(int, result=str)
    def get_url_at(self, row: int) -> str:
        if 0 <= row < len(self._channels):
            return self._channels[row].url
        return ""
