# deinterlace_filter.py
from PySide6.QtCore import QObject, Slot
from PySide6.QtMultimedia import QMediaPlayer, QVideoFrame, QVideoSink


class WindowsDeinterlacer(QObject):
    """Desentrelazador de campo en tiempo real sobre QVideoFrame (1080i -> 1080p) para Windows."""

    def __init__(self, player: QMediaPlayer, target_sink: QVideoSink, parent=None):
        super().__init__(parent)
        self._input_sink = QVideoSink(self)
        self._target_sink = target_sink
        self._input_sink.videoFrameChanged.connect(self._process_frame)
        player.setVideoSink(self._input_sink)

    @Slot(QVideoFrame)
    def _process_frame(self, frame: QVideoFrame) -> None:
        if not frame.isValid():
            return

        # Mapea el frame en modo lectura/escritura (copia de GPU a memoria si viene de D3D11)
        if frame.map(QVideoFrame.MapMode.ReadWrite):
            try:
                plane_count = frame.planeCount()
                for plane in range(plane_count):
                    height = frame.height() if plane == 0 else frame.height() // 2
                    stride = frame.bytesPerLine(plane)
                    if stride <= 0 or height < 2:
                        continue

                    ptr = frame.bits(plane)
                    buf = memoryview(ptr)
                    # Duplica cada línea par sobre la impar siguiente (Single-Field Bob instantáneo)
                    for y in range(0, height - 1, 2):
                        src_start = y * stride
                        dst_start = (y + 1) * stride
                        buf[dst_start : dst_start + stride] = buf[
                            src_start : src_start + stride
                        ]
            finally:
                frame.unmap()

        self._target_sink.setVideoFrame(frame)
