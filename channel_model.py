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

        # ... Mantén tus métodos roleNames, rowCount y data EXACTAMENTE IGUAL ...

    @Slot(str)
    def parse_m3u_content(self, content: str):
        """Algoritmo de parseo que ahora también detecta la dirección del servidor"""
        self.beginResetModel()
        self._channels = []
        self._base_url = None  # Inicializa la URL base de Tvheadend
        
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
                    
                    # NUEVO: Extrae de forma automática la IP y el Puerto de la primera URL que encuentre
                    if not self._base_url:
                        from urllib.parse import urlparse
                        parsed_url = urlparse(line)
                        if parsed_url.netloc:
                            # Guarda "http://192.168.1.10:9981" o cualquier dominio del archivo .m3u
                            self._base_url = f"{parsed_url.scheme}://{parsed_url.netloc}"
                    
                    current_name = ""
                    current_logo = None
                    current_ch_no = None
                    
        self.endResetModel()

    @Slot(int, result=str)
    def get_url_at(self, row: int) -> str:
        if 0 <= row < len(self._channels):
            return self._channels[row].url
        return ""

    # ACTUALIZADO: Cambiado de result=list a result='QVariant' para devolver un objeto JavaScript legible
    @Slot(str, result='QVariant')
    def fetch_current_epg(self, channel_name: str) -> dict:
        import urllib.request
        import urllib.parse
        import json
        
        # Respuesta por defecto en caso de fallo o ausencia de datos
        default_response = {
            "title": "Emisión en directo",
            "description": "Buscando información del evento actual en el flujo de Tvheadend..."
        }
        
        if not hasattr(self, '_base_url') or not self._base_url:
            return {
                "title": "Información de EPG no disponible",
                "description": "No se detectó la dirección del servidor en el archivo M3U."
            }
        
        try:
            encoded_name = urllib.parse.quote(channel_name)
            url = f"{self._base_url}/api/epg/events/grid?channel={encoded_name}&mode=now"
            
            req = urllib.request.Request(url, headers={'User-Agent': 'TdtPlayer-Native'})
            with urllib.request.urlopen(req, timeout=2.0) as response:
                data = json.loads(response.read().decode('utf-8'))
                
                if "entries" in data and len(data["entries"]) > 0:
                    event = data["entries"][0]
                    return {
                        "title": event.get("title", "Emisión en directo"),
                        "description": event.get("description", event.get("summary", "Sin descripción detallada disponible."))
                    }
                    
        except Exception as e:
            print(f"Error consultando la API dinámica de Tvheadend: {e}")
            
        return default_response