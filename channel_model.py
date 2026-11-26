# channel_model.py
import os

from PySide6.QtCore import (
    Property,
    QAbstractListModel,
    QCoreApplication,
    QModelIndex,
    Qt,
    QUrl,
    Signal,
    Slot,
)

from epg_repository import EpgRepository
from epg_worker import EpgPreloaderWorker
from hls_proxy import LocalHlsProxy
from logo_downloader import LogoDownloaderWorker
from m3u_parser import M3uParser


class ChannelModel(QAbstractListModel):
    NameRole = Qt.UserRole + 1
    UrlRole = Qt.UserRole + 2
    LogoRole = Qt.UserRole + 3
    ChNoRole = Qt.UserRole + 4
    EpgTitleRole = Qt.UserRole + 5

    logoCacheChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._channels = []
        self._worker = None
        self._downloader = None
        self._logo_cache = {}
        self._epg_title_cache = {}

        base_dir = os.path.dirname(os.path.abspath(__file__))
        self.cache_dir = os.path.join(base_dir, ".logo_cache")
        self.db_path = os.path.join(base_dir, "epg_cache.db")

        self._parser = M3uParser(self.cache_dir)
        self._repository = EpgRepository(self.db_path)
        self._hls_proxy = LocalHlsProxy()

        app = QCoreApplication.instance()
        if app is not None:
            app.aboutToQuit.connect(self.cleanup)

    def roleNames(self):
        return {
            self.NameRole: b"name",
            self.UrlRole: b"url",
            self.LogoRole: b"logo",
            self.ChNoRole: b"chNo",
            self.EpgTitleRole: b"epgTitle",
        }

    def rowCount(self, parent: QModelIndex = None) -> int:
        return len(self._channels)

    def _get_clean_epg_title(self, channel_name: str) -> str:
        clean_name = channel_name.strip().replace("\r", "").replace("\n", "")
        if clean_name in self._epg_title_cache:
            return self._epg_title_cache[clean_name]

        epg = self._repository.fetch_current_program(clean_name)
        title = ""
        if epg and epg.get("title"):
            raw = str(epg["title"]).strip()
            close_idx = raw.find("]")
            title = raw[close_idx + 1 :].strip() if raw.startswith("[") and close_idx != -1 else raw

        self._epg_title_cache[clean_name] = title
        return title

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole):
        if not index.isValid() or not (0 <= index.row() < len(self._channels)):
            return None

        ch = self._channels[index.row()]
        if role == self.NameRole:
            return ch.name
        if role == self.UrlRole:
            return self._hls_proxy.wrap_url(ch.url)
        if role == self.LogoRole:
            if not ch.logo:
                return ""
            local_file = QUrl(ch.logo).toLocalFile()
            return ch.logo if (local_file and os.path.exists(local_file)) else ""
        if role == self.ChNoRole:
            return ch.ch_no or ""
        if role == self.EpgTitleRole:
            return self._get_clean_epg_title(ch.name)
        return None

    @Property(dict, notify=logoCacheChanged)
    def logoCache(self) -> dict:
        return self._logo_cache

    def _stop_active_workers(self) -> None:
        for attr, signals in (
            ("_downloader", ("logo_downloaded", "finished")),
            ("_worker", ("epg_cache_ready",)),
        ):
            worker = getattr(self, attr)
            if worker is not None:
                for sig_name in signals:
                    try:
                        getattr(worker, sig_name).disconnect()
                    except RuntimeError:
                        pass
                if worker.isRunning():
                    worker.requestInterruption()
                    worker.wait(3000)
                setattr(self, attr, None)

    @Slot()
    def clear_logo_cache(self) -> None:
        self._stop_active_workers()
        self._parser.clear_cache_dir()

    @Slot()
    def refresh_sidebar_epg(self) -> None:
        self._epg_title_cache.clear()
        if self._channels:
            self.dataChanged.emit(
                self.index(0, 0), self.index(len(self._channels) - 1, 0), [self.EpgTitleRole]
            )

    @Slot(str, bool)
    def parse_m3u_content(self, content: str, clear_cache: bool = False) -> None:
        if clear_cache:
            self.clear_logo_cache()
        else:
            self._stop_active_workers()

        self.beginResetModel()
        self._epg_title_cache.clear()
        self._channels, download_queue, self._logo_cache, base_url = self._parser.parse(content)
        self.endResetModel()
        self.logoCacheChanged.emit()

        if download_queue:
            self._downloader = LogoDownloaderWorker(download_queue, self.cache_dir)
            self._downloader.logo_downloaded.connect(self._on_single_logo_downloaded)
            self._downloader.finished.connect(self._on_logos_downloaded)
            self._downloader.start()

        if base_url:
            self._worker = EpgPreloaderWorker(base_url, self.db_path)
            self._worker.epg_cache_ready.connect(self._on_worker_finished)
            self._worker.start()

    def _on_worker_finished(self, success: bool) -> None:
        if success and self._channels:
            self._epg_title_cache.clear()
            self.dataChanged.emit(
                self.index(0, 0), self.index(len(self._channels) - 1, 0), [self.EpgTitleRole]
            )

    def _on_single_logo_downloaded(self, row: int) -> None:
        if 0 <= row < len(self._channels):
            ch = self._channels[row]
            if ch.logo:
                self._logo_cache[ch.name] = ch.logo
            idx = self.index(row, 0)
            self.dataChanged.emit(idx, idx, [self.LogoRole])

    def _on_logos_downloaded(self) -> None:
        self.logoCacheChanged.emit()
        if self._channels:
            self.dataChanged.emit(
                self.index(0, 0), self.index(len(self._channels) - 1, 0), [self.LogoRole]
            )

    @Slot(int, result=str)
    def get_url_at(self, row: int) -> str:
        if 0 <= row < len(self._channels):
            return self._hls_proxy.wrap_url(self._channels[row].url)
        return ""

    @Slot(str, result="QVariant")
    def fetch_current_epg(self, channel_name: str) -> dict:
        return self._repository.fetch_current_program(channel_name)

    @Slot(str, result="QVariant")
    def fetch_next_epg(self, channel_name: str) -> dict:
        return self._repository.fetch_next_program(channel_name)

    @Slot()
    def cleanup(self) -> None:
        self._stop_active_workers()
        if getattr(self, "_repository", None) is not None:
            self._repository.close()
        if getattr(self, "_hls_proxy", None) is not None:
            self._hls_proxy.stop()
