# screenshot_helper.py
import os
import re
import sys
import threading
from datetime import datetime

from PySide6.QtCore import QObject, QPointF, QRect, QSize, QStandardPaths, Qt, Signal, Slot


class ScreenshotHelper(QObject):
    screenshotSaved = Signal(str)
    screenshotFailed = Signal(str)

    def __init__(self, video_sink=None, parent=None):
        super().__init__(parent)
        self._video_sink = video_sink
        self._window = None
        self._qml_item = None

    def set_video_sink(self, video_sink) -> None:
        self._video_sink = video_sink

    def set_qml_capture_target(self, window, qml_item=None) -> None:
        self._window = window
        self._qml_item = qml_item

    def _build_save_path(self, channel_name: str) -> tuple[str, str]:
        pictures_dir = QStandardPaths.writableLocation(QStandardPaths.PicturesLocation)
        if not pictures_dir:
            pictures_dir = os.path.join(os.path.expanduser("~"), "Pictures")
        save_dir = os.path.join(pictures_dir, "TdtPlayer")

        safe_channel = re.sub(r"[^\w\-]+", "_", channel_name.strip()).strip("_") or "TDT"
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        file_path = os.path.join(save_dir, f"{safe_channel}_{timestamp}.png")
        return save_dir, file_path

    def _save_async(self, image, save_dir: str, file_path: str) -> None:
        self.screenshotSaved.emit(file_path)

        def _save_worker(img, out_dir, path):
            try:
                os.makedirs(out_dir, exist_ok=True)
                if not img.save(path, "PNG"):
                    self.screenshotFailed.emit("Error al escribir el archivo PNG")
            except Exception as exc:
                self.screenshotFailed.emit(str(exc))

        threading.Thread(
            target=_save_worker, args=(image, save_dir, file_path), daemon=True
        ).start()

    def _get_native_stream_size(self) -> QSize:
        if self._qml_item is not None:
            w = self._qml_item.property("videoTexWidth")
            h = self._qml_item.property("videoTexHeight")
            if w and h and int(round(w)) > 0 and int(round(h)) > 0:
                return QSize(int(round(w)), int(round(h)))

        if self._video_sink is not None:
            frame = self._video_sink.videoFrame()
            if frame.isValid() and not frame.size().isEmpty():
                return frame.size()

        return QSize()

    @Slot(str)
    def capture_frame(self, channel_name: str = "") -> None:
        # Windows: QQuickWindow.grabWindow() captura el grafo RHI activo (con shaders aplicados,
        # sin congelarse en DWM y sin invertir texturas P010).
        if sys.platform == "win32" and self._window is not None and hasattr(self._window, "grabWindow"):
            full_img = self._window.grabWindow()
            if not full_img.isNull():
                image = full_img
                if self._qml_item is not None and hasattr(self._qml_item, "mapToScene"):
                    dpr = self._window.devicePixelRatio()
                    top_left = self._qml_item.mapToScene(QPointF(0, 0))
                    crop_rect = QRect(
                        int(round(top_left.x() * dpr)),
                        int(round(top_left.y() * dpr)),
                        int(round(self._qml_item.width() * dpr)),
                        int(round(self._qml_item.height() * dpr)),
                    ).intersected(full_img.rect())
                    if crop_rect.isValid():
                        image = full_img.copy(crop_rect)

                native_size = self._get_native_stream_size()
                if native_size.isValid() and image.size() != native_size:
                    image = image.scaled(
                        native_size,
                        Qt.AspectRatioMode.IgnoreAspectRatio,
                        Qt.TransformationMode.SmoothTransformation,
                    )

                save_dir, file_path = self._build_save_path(channel_name)
                self._save_async(image, save_dir, file_path)
                return

        # Linux: exactamente el método original sin tocar
        if self._window is not None:
            scr = self._window.screen()
            if scr is not None:
                pixmap = scr.grabWindow(self._window.winId())
                full_img = pixmap.toImage()
                if not full_img.isNull():
                    image = full_img
                    if self._qml_item is not None and hasattr(self._qml_item, "mapToScene"):
                        dpr = self._window.devicePixelRatio()
                        top_left = self._qml_item.mapToScene(QPointF(0, 0))
                        crop_rect = QRect(
                            int(round(top_left.x() * dpr)),
                            int(round(top_left.y() * dpr)),
                            int(round(self._qml_item.width() * dpr)),
                            int(round(self._qml_item.height() * dpr)),
                        ).intersected(full_img.rect())
                        if crop_rect.isValid():
                            image = full_img.copy(crop_rect)

                    save_dir, file_path = self._build_save_path(channel_name)
                    self._save_async(image, save_dir, file_path)
                    return

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

        save_dir, file_path = self._build_save_path(channel_name)
        self._save_async(image, save_dir, file_path)
