# screenshot_helper.py
import os
import re
import threading
from datetime import datetime

from PySide6.QtCore import QObject, QStandardPaths, Signal, Slot


class ScreenshotHelper(QObject):
    screenshotSaved = Signal(str)
    screenshotFailed = Signal(str)

    def __init__(self, video_sink=None, parent=None):
        super().__init__(parent)
        self._video_sink = video_sink

    def set_video_sink(self, video_sink) -> None:
        self._video_sink = video_sink

    @Slot(str)
    def capture_frame(self, channel_name: str = "") -> None:
        if self._video_sink is None:
            self.screenshotFailed.emit("Sin salida de vídeo activa")
            return

        frame = self._video_sink.videoFrame()
        if not frame.isValid():
            self.screenshotFailed.emit("No hay fotograma disponible")
            return

        image = frame.toImage()
        if image.isNull():
            self.screenshotFailed.emit("No se pudo convertir el fotograma")
            return

        pictures_dir = QStandardPaths.writableLocation(QStandardPaths.PicturesLocation)
        if not pictures_dir:
            pictures_dir = os.path.join(os.path.expanduser("~"), "Pictures")
        save_dir = os.path.join(pictures_dir, "TdtPlayer")

        safe_channel = re.sub(r"[^\w\-]+", "_", channel_name.strip()).strip("_") or "TDT"
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        file_path = os.path.join(save_dir, f"{safe_channel}_{timestamp}.png")

        # Feedback visual instantáneo en 0 ms al capturar el fotograma en memoria
        self.screenshotSaved.emit(file_path)

        def _save_worker(img, path):
            try:
                os.makedirs(os.path.dirname(path), exist_ok=True)
                if not img.save(path, "PNG"):
                    self.screenshotFailed.emit("Error al escribir el archivo PNG")
            except Exception as exc:
                self.screenshotFailed.emit(str(exc))

        threading.Thread(
            target=_save_worker, args=(image, file_path), daemon=True
        ).start()
