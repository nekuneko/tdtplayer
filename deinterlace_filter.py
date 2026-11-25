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
    if pixel_format in _YUV420_FORMATS:
        return frame_height // 2
    return frame_height


def _is_frame_interlaced(luma_arr: np.ndarray) -> bool:
    """Detecta en <0.05 ms si el plano de luminancia presenta efecto peine (1080i vs 1080p)."""
    rows, cols = luma_arr.shape
    if rows < 200 or cols < 200:
        return False

    y0 = (rows // 2) - 60
    y1 = y0 + 120
    sample = luma_arr[y0:y1, ::4].astype(np.int16)

    top = sample[0:-2:2]
    odd = sample[1:-1:2]
    n = odd.shape[0]
    bot = sample[2::2][:n]
    top = top[:n]

    comb = np.mean(np.abs((top + bot) - (odd << 1)))
    field_diff = np.mean(np.abs(top - bot))
    return bool(comb > 14.0 and comb > (field_diff * 1.15))


def _interpolate_odd_rows(arr: np.ndarray) -> None:
    """Interpola cada línea impar como media exacta de las líneas pares adyacentes."""
    rows = arr.shape[0]
    if rows < 3:
        return
    odd_slice = arr[1 : rows - 1 : 2]
    n = odd_slice.shape[0]
    top_slice = arr[0 : rows - 2 : 2][:n]
    bot_slice = arr[2:rows:2][:n]
    avg = (top_slice.astype(np.uint16) + bot_slice.astype(np.uint16)) >> 1
    odd_slice[:] = avg.astype(np.uint8)
    if rows % 2 == 0:
        arr[-1] = arr[-2]


class WindowsDeinterlacer(QObject):
    """Desentrelazador adaptativo (1080i/576i -> progresivo; 1080p y 2160p UHD intactos en GPU)."""

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
        # 720p y 2160p (4K UHD) permanecen en GPU sin copiarse a RAM
        if h not in (576, 1080):
            self._target_sink.setVideoFrame(frame)
            return

        fmt = frame.pixelFormat()
        plane_count = frame.planeCount()

        if frame.map(QVideoFrame.MapMode.ReadWrite):
            try:
                y_rows = _plane_rows(h, fmt, 0)
                y_stride = frame.bytesPerLine(0)
                y_ptr = frame.bits(0)
                if y_ptr is not None and y_stride > 0:
                    y_arr = np.frombuffer(y_ptr, dtype=np.uint8, count=y_rows * y_stride).reshape((y_rows, y_stride))
                    if h == 1080 and not _is_frame_interlaced(y_arr):
                        frame.unmap()
                        self._target_sink.setVideoFrame(frame)
                        return

                for plane in range(plane_count):
                    rows = _plane_rows(h, fmt, plane)
                    stride = frame.bytesPerLine(plane)
                    ptr = frame.bits(plane)
                    if ptr is not None and rows >= 3 and stride > 0:
                        arr = np.frombuffer(ptr, dtype=np.uint8, count=rows * stride).reshape((rows, stride))
                        _interpolate_odd_rows(arr)
            finally:
                if frame.isMapped():
                    frame.unmap()
            self._target_sink.setVideoFrame(frame)
            return

        if frame.map(QVideoFrame.MapMode.ReadOnly):
            y_rows = _plane_rows(h, fmt, 0)
            y_stride = frame.bytesPerLine(0)
            y_ptr = frame.bits(0)
            if y_ptr is not None and y_stride > 0:
                y_arr = np.frombuffer(y_ptr, dtype=np.uint8, count=y_rows * y_stride).reshape((y_rows, y_stride))
                if h == 1080 and not _is_frame_interlaced(y_arr):
                    frame.unmap()
                    self._target_sink.setVideoFrame(frame)
                    return

            out_frame = QVideoFrame(frame.surfaceFormat())
            mapped_out = out_frame.map(QVideoFrame.MapMode.WriteOnly)
            try:
                if mapped_out:
                    for plane in range(plane_count):
                        rows = _plane_rows(h, fmt, plane)
                        stride = min(frame.bytesPerLine(plane), out_frame.bytesPerLine(plane))
                        src_ptr = frame.bits(plane)
                        dst_ptr = out_frame.bits(plane)
                        if src_ptr is not None and dst_ptr is not None and rows >= 3 and stride > 0:
                            src_arr = np.frombuffer(src_ptr, dtype=np.uint8, count=rows * stride).reshape((rows, stride))
                            dst_arr = np.frombuffer(dst_ptr, dtype=np.uint8, count=rows * stride).reshape((rows, stride))
                            np.copyto(dst_arr, src_arr)
                            _interpolate_odd_rows(dst_arr)
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
