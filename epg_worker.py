# epg_worker.py
import json
import urllib.request
import urllib.parse
from datetime import datetime
from PySide6.QtCore import QThread, Signal

class EpgPreloaderWorker(QThread):
    epg_cache_ready = Signal(dict)

    def __init__(self, base_url: str):
        super().__init__()
        self.base_url = base_url

    def run(self):
        cache = {}
        if not self.base_url:
            self.epg_cache_ready.emit(cache)
            return
        try:
            url = f"{self.base_url}/api/epg/events/grid?limit=2000&mode=now"
            req = urllib.request.Request(url, headers={'User-Agent': 'TdtPlayer-Native'})
            
            with urllib.request.urlopen(req, timeout=3.0) as response:
                data = json.loads(response.read().decode('utf-8'))
                
                if "entries" in data and isinstance(data["entries"], list):
                    for program in data["entries"]:
                        ch_name = program.get("channelName") or program.get("channel")
                        
                        if ch_name:
                            time_str = ""
                            start_ts = program.get("start")
                            stop_ts = program.get("stop")
                            
                            if start_ts and stop_ts:
                                start_dt = datetime.fromtimestamp(start_ts)
                                stop_dt = datetime.fromtimestamp(stop_ts)
                                time_str = f"[{start_dt.strftime('%H:%M')} - {stop_dt.strftime('%H:%M')}] "

                            title = program.get("title", "Emisión en directo")
                            full_title = f"{time_str}{title}"

                            cache[str(ch_name).strip()] = {
                                "title": full_title,
                                "description": program.get("description", program.get("summary", "Sin descripción detallada disponible."))
                            }
        except Exception as e:
            print(f"Error en la precarga masiva de la RAM: {e}")
            
        self.epg_cache_ready.emit(cache)
