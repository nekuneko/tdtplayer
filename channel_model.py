# channel_model.py
import hashlib
import os
import re
import urllib.parse

from PySide6.QtCore import Property, QAbstractListModel, QModelIndex, Qt, Signal, Slot

from epg_repository import EpgRepository
from epg_worker import EpgPreloaderWorker
from logo_downloader import LogoDownloaderWorker
from m3u_channel import M3uChannel


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
        self._downloader = None
        self._logo_cache = {}

        base_dir = os.path.dirname(os.path.abspath(__file__))
        self.cache_dir = os.path.join(base_dir, ".logo_cache")
        self.db_path = os.path.join(base_dir, "epg_cache.db")

        self._repository = EpgRepository(self.db_path)

    def roleNames(self):
        return {
            self.NameRole: b"name",
            self.UrlRole: b"url",
            self.LogoRole: b"logo",
            self.ChNoRole: b"chNo",
        }

    # Instanciación limpia en el cuerpo para evitar referencias mutables fantasma
    def rowCount(self, parent: QModelIndex = None) -> int:
        if parent is None:
            parent = QModelIndex()
        return len(self._channels)

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole):
        if not index.isValid() or not (0 <= index.row() < len(self._channels)):
            return None

        channel = self._channels[index.row()]
        if role == self.NameRole:
            return channel.name
        elif role == self.UrlRole:
            return channel.url
        elif role == self.LogoRole:
            return channel.logo or ""
        elif role == self.ChNoRole:
            return channel.ch_no or ""
        return None

    @Property(dict, notify=logoCacheChanged)
    def logoCache(self) -> dict:
        return self._logo_cache

    @Slot(str)
    def parse_m3u_content(self, content: str) -> None:
        self.beginResetModel()
        self._channels = []
        self._base_url = None
        self._logo_cache = {}

        lines = content.split("\n")
        logo_regex = re.compile(r'tvg-logo="([^"]+)"')
        ch_no_regex = re.compile(r'tvg-chno="([^"]+)"')
        current_name, current_logo, current_ch_no = "", None, None
        download_queue = []
        os.makedirs(self.cache_dir, exist_ok=True)

        for line in lines:
            line = line.strip()
            if line.startswith("#EXTINF:"):
                comma_index = line.rfind(",")
                current_name = (
                    line[comma_index + 1 :].strip().replace("\r", "")
                    if comma_index != -1
                    else "Canal Desconocido"
                )
                logo_match = logo_regex.search(line)
                current_logo = logo_match.group(1) if logo_match else None
                ch_no_match = ch_no_regex.search(line)
                current_ch_no = ch_no_match.group(1) if ch_no_match else None
            # Fusión optimizada en una sola pasada de C-Engine mediante tupla
            elif line.startswith(("http://", "https://")):
                if current_name:
                    clean_name = current_name.strip().replace("\r", "")
                    local_logo_path = ""

                    if current_logo and current_logo.startswith(
                        ("http://", "https://")
                    ):
                        parsed_url = urllib.parse.urlparse(current_logo)
                        file_ext = os.path.splitext(parsed_url.path)
                        actual_ext = (
                            file_ext[1]
                            if file_ext and len(file_ext) > 1 and len(file_ext[1]) <= 5
                            else ".png"
                        )
                        file_name = (
                            hashlib.md5(clean_name.encode("utf-8")).hexdigest()
                            + actual_ext
                        )
                        full_local_path = os.path.join(self.cache_dir, file_name)
                        download_queue.append((current_logo, full_local_path))
                        local_logo_path = "file://" + full_local_path
                    else:
                        local_logo_path = current_logo or ""

                    self._channels.append(
                        M3uChannel(
                            name=clean_name,
                            url=line,
                            logo=local_logo_path,
                            ch_no=current_ch_no,
                        )
                    )
                    if local_logo_path:
                        self._logo_cache[clean_name] = local_logo_path

                    if not self._base_url:
                        parsed_url = urllib.parse.urlparse(line)
                        if parsed_url.netloc:
                            self._base_url = (
                                f"{parsed_url.scheme}://{parsed_url.netloc}"
                            )

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

    def _on_worker_finished(self, success: bool) -> None:
        if success and len(self._channels) > 0:
            self.dataChanged.emit(
                self.index(0, 0), self.index(len(self._channels) - 1, 0), []
            )

    @Slot(int, result=str)
    def get_url_at(self, row: int) -> str:
        return self._channels[row].url if 0 <= row < len(self._channels) else ""

    @Slot(str, result="QVariant")
    def fetch_current_epg(self, channel_name: str) -> dict:
        return self._repository.fetch_current_program(channel_name)

    @Slot(str, result="QVariant")
    def fetch_next_epg(self, channel_name: str) -> dict:
        return self._repository.fetch_next_program(channel_name)

    def __del__(self) -> None:
        if hasattr(self, "_repository"):
            self._repository.close()
