# epg_worker.py
import urllib.request
import urllib.parse
import json
from datetime import datetime
from PySide6.QtCore import QThread, Signal

class EpgPreloaderWorker(QThread):
    epg_cache_ready = Signal(dict)

    def __init__(self, base_url):
        super().__init__()
        self.base_url = base_url

    def run(self):
        # 🚀 Pedimos el grid global masivo para procesarlo todo de una sola tacada por red
        api_url = f"{self.base_url}/api/epg/events/grid?limit=999999"
        headers = {'User-Agent': 'TdtPlayer-Preloader'}
        
        try:
            req = urllib.request.Request(api_url, headers=headers)
            with urllib.request.urlopen(req, timeout=8.0) as response:
                raw_json = json.loads(response.read().decode('utf-8'))
                entries = raw_json.get("entries", [])
                
                # Diccionario intermedio para agrupar los nodos crudos por canal
                grouped_channels = {}
                
                for entry in entries:
                    ch_name = entry.get("channelName")
                    if not ch_name:
                        continue
                    
                    clean_ch_name = str(ch_name).strip()
                    if clean_ch_name not in grouped_channels:
                        grouped_channels[clean_ch_name] = []
                    
                    grouped_channels[clean_ch_name].append(entry)
                
                final_processed_cache = {}
                current_timestamp = datetime.now().timestamp()
                
                # Procesamos canal por canal aplicando la ordenación cronológica que propusiste
                for clean_ch_name, event_list in grouped_channels.items():
                    # 🚀 ALINEACIÓN DE HISTORIAL: Ordenamos de forma ascendente por hora de inicio (start)
                    event_list.sort(key=lambda x: x.get("start", 0))
                    
                    processed_events = []
                    for entry in event_list:
                        start_ts = entry.get("start", 0)
                        stop_ts = entry.get("stop", 0)
                        
                        # Filtro de obsolescencia: Ignoramos eventos antiguos que ya terminaron hace horas
                        if stop_ts < current_timestamp:
                            continue
                            
                        time_str = "[--:-- - --:--]"
                        try:
                            if start_ts > 0 and stop_ts > 0:
                                s_dt = datetime.fromtimestamp(start_ts)
                                e_dt = datetime.fromtimestamp(stop_ts)
                                time_str = f"[{s_dt.strftime('%H:%M')} - {e_dt.strftime('%H:%M')}]"
                        except Exception:
                            pass

                        program_node = {
                            "title": f"{time_str} {entry.get('title', 'Emisión en directo')}",
                            "description": entry.get("description") or entry.get("summary") or "Sin descripción detallada disponible."
                        }
                        processed_events.append(program_node)
                    
                    # Guardamos la lista ordenada final si contiene datos
                    if processed_events:
                        final_processed_cache[clean_ch_name] = processed_events
                
                # Despachamos la caché final estructurada hacia el modelo de Qt
                self.epg_cache_ready.emit(final_processed_cache)
                
        except Exception as e:
            print(f"Error asíncrono ordenando la parrilla EPG: {e}")
            self.epg_cache_ready.emit({})
