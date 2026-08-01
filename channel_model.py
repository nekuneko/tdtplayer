# channel_model.py
import re
import json
import urllib.request
import urllib.parse
from PySide6.QtCore import QAbstractListModel, Qt, QModelIndex, Slot, QThread, Signal

# ===================================================================
# 🛠️ REPARADO: PROCESAMIENTO CORRECTO DEL ARRAY MASIVO DE TVHEADEND
# ===================================================================
class EpgPreloaderWorker(QThread):
    epg_cache_ready = Signal(dict)

    def __init__(self, base_url):
        super().__init__()
        self.base_url = base_url

    def run(self):
        cache = {}
        if not self.base_url:
            self.epg_cache_ready.emit(cache)
            return
        try:
            from datetime import datetime
            url = f"{self.base_url}/api/epg/events/grid?limit=2000&mode=now"
            req = urllib.request.Request(url, headers={'User-Agent': 'TdtPlayer-Native'})
            
            with urllib.request.urlopen(req, timeout=3.0) as response:
                data = json.loads(response.read().decode('utf-8'))
                
                if "entries" in data and isinstance(data["entries"], list):
                    for program in data["entries"]:
                        ch_name = program.get("channelName") or program.get("channel")
                        
                        if ch_name:
                            # 🕒 NUEVO: Extracción y formateo dinámico de horas de inicio y fin
                            time_str = ""
                            start_ts = program.get("start")
                            stop_ts = program.get("stop")
                            
                            if start_ts and stop_ts:
                                start_dt = datetime.fromtimestamp(start_ts)
                                stop_dt = datetime.fromtimestamp(stop_ts)
                                time_str = f"[{start_dt.strftime('%H:%M')} - {stop_dt.strftime('%H:%M')}] "

                            title = program.get("title", "Emisión en directo")
                            # Acoplamos el horario justo al principio del título del programa
                            full_title = f"{time_str}{title}"

                            cache[str(ch_name).strip()] = {
                                "title": full_title,
                                "description": program.get("description", program.get("summary", "Sin descripción detallada disponible."))
                            }
        except Exception as e:
            print(f"Error en la precarga masiva de la RAM: {e}")
            
        self.epg_cache_ready.emit(cache)


# ===================================================================
# ACTUALIZADO: MÉTODO DE RESCATE CON HORARIOS
# ===================================================================
    @Slot(str, result='QVariant')
    def fetch_current_epg(self, channel_name: str) -> dict:
        if not channel_name:
            return {"title": "Sin canal", "description": ""}
            
        search_name = str(channel_name).strip()
        
        if search_name in self._epg_cache:
            return self._epg_cache[search_name]
            
        try:
            from datetime import datetime
            encoded_name = urllib.parse.quote(search_name)
            url = f"{self._base_url}/api/epg/events/grid?channel={encoded_name}&mode=now"
            req = urllib.request.Request(url, headers={'User-Agent': 'TdtPlayer-Native'})
            
            with urllib.request.urlopen(req, timeout=0.5) as response:
                data = json.loads(response.read().decode('utf-8'))
                if "entries" in data and len(data["entries"]) > 0:
                    program = data["entries"][0]
                    
                    # 🕒 NUEVO: El mismo formateo de horas para el método de rescate
                    time_str = ""
                    start_ts = program.get("start")
                    stop_ts = program.get("stop")
                    if start_ts and stop_ts:
                        start_dt = datetime.fromtimestamp(start_ts)
                        stop_dt = datetime.fromtimestamp(stop_ts)
                        time_str = f"[{start_dt.strftime('%H:%M')} - {stop_dt.strftime('%H:%M')}] "

                    title = program.get("title", "Emisión en directo")
                    full_title = f"{time_str}{title}"

                    res = {
                        "title": full_title,
                        "description": program.get("description", program.get("summary", "Sin descripción detallada disponible."))
                    }
                    self._epg_cache[search_name] = res
                    return res
        except Exception:
            pass
            
        return {
            "title": "Emisión en directo",
            "description": "Buscando información del evento actual en el flujo de Tvheadend..."
        }


class ChannelModel(QAbstractListModel):
    NameRole = Qt.UserRole + 1
    UrlRole = Qt.UserRole + 2
    LogoRole = Qt.UserRole + 3
    ChNoRole = Qt.UserRole + 4

    def __init__(self, parent=None):
        super().__init__(parent)
        self._channels = []
        self._base_url = None
        self._epg_cache = {} # 🧠 Memoria RAM: Almacenamiento instantáneo del EPG

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
                    from m3u_channel import M3uChannel
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
        
        # Disparamos la precarga masiva del EPG en segundo plano inmediatamente tras parsear el M3U
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

    # 🛠️ REPARADO: La consulta ahora lee de la memoria RAM interna. 
    # Tarda 0 milisegundos, eliminando cualquier espera de red en el zapping.
    @Slot(str, result='QVariant')
    def fetch_current_epg(self, channel_name: str) -> dict:
        # Si el canal ya está en nuestra base de datos local de la RAM, lo devolvemos de golpe
        if channel_name in self._epg_cache:
            return self._epg_cache[channel_name]
            
        # Si no se encuentra en la caché, hacemos una consulta rápida de rescate
        try:
            encoded_name = urllib.parse.quote(channel_name)
            url = f"{self._base_url}/api/epg/events/grid?channel={encoded_name}&mode=now"
            req = urllib.request.Request(url, headers={'User-Agent': 'TdtPlayer-Native'})
            with urllib.request.urlopen(req, timeout=0.4) as response:
                data = json.loads(response.read().decode('utf-8'))
                if "entries" in data and len(data["entries"]) > 0:
                    event = data["entries"][0]
                    res = {
                        "title": event.get("title", "Emisión en directo"),
                        "description": event.get("description", event.get("summary", "Sin descripción detallada disponible."))
                    }
                    self._epg_cache[channel_name] = res # Guardamos en caché para la próxima vez
                    return res
        except Exception:
            pass
            
        return {
            "title": "Emisión en directo",
            "description": "Buscando información del evento actual en el flujo de Tvheadend..."
        }
