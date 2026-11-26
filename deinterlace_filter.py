# deinterlace_filter.py
import numpy as np
from PySide6.QtCore import QObject, Slot
from PySide6.QtMultimedia import QMediaPlayer, QVideoFrame, QVideoFrameFormat, QVideoSink

_YUV420_FORMATS = {
    QVideoFrameFormat.PixelFormat.Format_NV12,
    QVideoFrameFormat.PixelFormat.Format_NV21,
    QVideoFrameFormat.PixelFormat.Format_YUV420P,
    QVideoFrameFormat.PixelFormat.Format_YV12,
    QVideoFrameFormat.PixelFormat.Format_IMC1,
    QVideoFrameFormat.PixelFormat.Format_IMC2,
    QVideoFrameFormat.PixelFormat.Format_IMC3,
    QVideoFrameFormat.PixelFormat.Format_IMC4,
    QVideoFrameFormat.PixelFormat.Format_P010,
    QVideoFrameFormat.PixelFormat.Format_P016,
}


def _plane_rows(frame_height: int, pixel_format: QVideoFrameFormat.PixelFormat, plane: int) -> int:
    if plane == 0:
        return frame_height
    return (frame_height // 2) if pixel_format in _YUV420_FORMATS else frame_height


def _motion_adaptive_deinterlace(arr: np.ndarray, threshold: int = 14) -> None:
    """Desentrelazado adaptativo por píxel: interpola solo donde hay movimiento y conserva nitidez en zonas fijas."""
    rows, _ = arr.shape
    if rows < 3:
        return

    odd = arr[1 : rows - 1 : 2]
    n, _ = odd.shape
    top = arr[0 : rows - 2 : 2][:n].astype(np.int16)
    bot = arr[2:rows:2][:n].astype(np.int16)
    odd_i16 = odd.astype(np.int16)

    avg = (top + bot) >> 1
    comb_err = np.abs(odd_i16 - avg)
    vertical_grad = np.abs(top - bot) >> 1
    moving_mask = comb_err > (vertical_grad + threshold)

    odd[:] = np.where(moving_mask, avg, odd_i16).astype(np.uint8)
    if rows % 2 == 0:
        arr[-1] = arr[-2]


def _map_plane(frame: QVideoFrame, plane: int, rows: int, stride: int) -> np.ndarray | None:
    ptr = frame.bits(plane)
    if ptr is None or rows < 3 or stride <= 0:
        return None
    return np.frombuffer(ptr, dtype=np.uint8, count=rows * stride).reshape((rows, stride))


class WindowsDeinterlacer(QObject):
    """Desentrelazador adaptativo al movimiento (1080i/576i -> progresivo nítido; 720p/2160p intactos en GPU)."""

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

        h = frame.height()
        if h not in (576, 1080):
            self._target_sink.setVideoFrame(frame)
            return

        fmt = frame.pixelFormat()
        planes = frame.planeCount()

        if frame.map(QVideoFrame.MapMode.ReadWrite):
            try:
                for p in range(planes):
                    arr = _map_plane(frame, p, _plane_rows(h, fmt, p), frame.bytesPerLine(p))
                    if arr is not None:
                        _motion_adaptive_deinterlace(arr, threshold=14 if p == 0 else 10)
            finally:
                frame.unmap()
            self._target_sink.setVideoFrame(frame)
            return

        if frame.map(QVideoFrame.MapMode.ReadOnly):
            out_frame = QVideoFrame(frame.surfaceFormat())
            mapped_out = out_frame.map(QVideoFrame.MapMode.WriteOnly)
            try:
                if mapped_out:
                    for p in range(planes):
                        rows = _plane_rows(h, fmt, p)
                        stride = min(frame.bytesPerLine(p), out_frame.bytesPerLine(p))
                        src = _map_plane(frame, p, rows, stride)
                        dst = _map_plane(out_frame, p, rows, stride)
                        if src is not None and dst is not None:
                            np.copyto(dst, src)
                            _motion_adaptive_deinterlace(dst, threshold=14 if p == 0 else 10)
            finally:
                if mapped_out:
                    out_frame.unmap()
                frame.unmap()

            if mapped_out:
                out_frame.setStartTime(frame.startTime())
                out_frame.setEndTime(frame.endTime())
                self._target_sink.setVideoFrame(out_frame)
                return

        self._target_sink.setVideoFrame(frame)
