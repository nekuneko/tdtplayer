# main.py
import gc
import os
import sys


def configure_environment() -> None:
    """Configura variables de entorno y rutas nativas de Qt/FFmpeg antes de cargar PySide6."""
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"

    # 🚀 MOTOR DE SINCRONIZACIÓN NATIVO PARA PERFIL 'PASS' (MPEG-TS EN BRUTO)
    # Ampliamos el análisis de cabeceras para que Qt Multimedia asimile el flujo de BeMad HD
    # junto con todas sus pistas síncronas (EPG, audios alternos y teletexto) de una sola pasada.
    os.environ["QT_MULTIMEDIA_FFMPEG_OPTIONS"] = (
        "probesize=10000000;analyzeduration=5000000;fflags=discardcorrupt;rw_timeout=5000000;"
        "allowed_segment_extensions=ALL;"
        "user_agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
    )

    # Permitir explícitamente que los objetos XMLHttpRequest de QML lean archivos locales
    os.environ["QML_XHR_ALLOW_FILE_READ"] = "1"

    if sys.platform == "win32":
        # Registra el directorio de DLLs de PySide6 en Windows (necesario en entornos Store/venv)
        import ctypes
        import PySide6

        ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(
            "TvheadendNative.TdtPlayer.1"
        )

        pyside_dir = os.path.dirname(PySide6.__file__)
        os.add_dll_directory(pyside_dir)
        os.environ["PATH"] = pyside_dir + os.pathsep + os.environ.get("PATH", "")

        # Aceleración por hardware nativa de Windows (Direct3D 11)
        os.environ["QT_MULTIMEDIA_FFMPEG_HWACCEL"] = "d3d11va"
    else:
        # Fuerza el backend de integración EGL estable para la GPU Intel en servidores X11 (Linux)
        os.environ["QT_XCB_GL_INTEGRATION"] = "xcb_egl"

        # Forzar el uso estricto de la API de aceleración por hardware de Intel (VA-API)
        os.environ["QT_MULTIMEDIA_FFMPEG_HWACCEL"] = "vaapi"


configure_environment()

from PySide6.QtCore import QObject, Qt, QUrl, Slot  # noqa: E402
from PySide6.QtGui import QGuiApplication, QIcon  # noqa: E402
from PySide6.QtMultimedia import QMediaPlayer, QVideoFrameFormat, QVideoSink  # noqa: E402
from PySide6.QtQml import QQmlApplicationEngine  # noqa: E402
from PySide6.QtQuick import QQuickItem  # noqa: E402

from channel_model import ChannelModel  # noqa: E402
from screenshot_helper import ScreenshotHelper  # noqa: E402


class CursorHelper(QObject):
    """Controla la ocultación real del cursor a nivel de aplicación (Windows/Linux)."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self._hidden = False

    @Slot(bool)
    def set_hidden(self, hide: bool) -> None:
        if hide and not self._hidden:
            QGuiApplication.setOverrideCursor(Qt.BlankCursor)
            self._hidden = True
        elif not hide and self._hidden:
            QGuiApplication.restoreOverrideCursor()
            self._hidden = False


def main():
    # Identificadores estáticos obligatorios para habilitar el componente Settings en QML
    QGuiApplication.setOrganizationName("TvheadendNative")
    QGuiApplication.setOrganizationDomain("tvheadend.native")
    QGuiApplication.setApplicationName("TvheadendNativePlayer")

    app = QGuiApplication(sys.argv)

    # Carga el icono de la aplicación desde docs/icon.png (compatible con .exe y desarrollo)
    base_dir = getattr(
        sys, "_MEIPASS", os.path.dirname(os.path.abspath(__file__))
    )
    icon_path = os.path.join(base_dir, "docs", "icon.png")
    if os.path.exists(icon_path):
        app.setWindowIcon(QIcon(icon_path))

    engine = QQmlApplicationEngine()

    # Asegura que Qt6 encuentre los archivos .qml modularizados de la subcarpeta qml/
    qml_dir = (
        os.path.join(base_dir, "qml")
        if os.path.exists(os.path.join(base_dir, "qml"))
        else base_dir
    )
    engine.addImportPath(qml_dir)

    def handle_qml_warnings(warnings):
        for warning in warnings:
            print(f"Error en QML: {warning.toString()}", file=sys.stderr)

    engine.warnings.connect(handle_qml_warnings)

    channel_model = ChannelModel()
    screenshot_helper = ScreenshotHelper(parent=app)
    cursor_helper = CursorHelper(parent=app)

    context = engine.rootContext()
    context.setContextProperty("channelModel", channel_model)
    context.setContextProperty("screenshotHelper", screenshot_helper)
    context.setContextProperty("cursorHelper", cursor_helper)

    qml_file = os.path.join(qml_dir, "main.qml")
    engine.load(QUrl.fromLocalFile(qml_file))

    if not engine.rootObjects():
        print(
            "Error crítico: No se pudieron cargar los objetos raíz de QML.",
            file=sys.stderr,
        )
        sys.exit(-1)

    root_obj = engine.rootObjects()[0]
    if os.path.exists(icon_path):
        root_obj.setIcon(QIcon(icon_path))

    # En QML VideoOutput expone la propiedad 'videoSink' (QVideoSink)
    video_out = root_obj.findChild(QVideoSink)
    if video_out:
        screenshot_helper.set_video_sink(video_out)

    # Vincula la ventana raíz y el ShaderEffect de GPU al capturador de pantalla (Windows y Linux)
    gpu_shader_item = root_obj.findChild(QQuickItem, "gpuVideoPipeline")
    screenshot_helper.set_qml_capture_target(root_obj, gpu_shader_item)

    # Detector multiplataforma de espacio de color HDR/HLG y cadencia 50 tbr vs 25 tbr
    root_obj.setProperty("isHdrStream", False)
    root_obj.setProperty("is50TbrStream", False)
    _last_frame_start = 0

    def _reset_stream_state(_source=None):
        nonlocal _last_frame_start
        _last_frame_start = 0
        if root_obj.property("isHdrStream"):
            root_obj.setProperty("isHdrStream", False)
        if root_obj.property("is50TbrStream"):
            root_obj.setProperty("is50TbrStream", False)

    media_player = root_obj.findChild(QMediaPlayer)
    if media_player:
        media_player.sourceChanged.connect(_reset_stream_state)

    def _check_video_stream_props(frame):
        nonlocal _last_frame_start
        if not frame.isValid():
            return

        sf = frame.surfaceFormat()
        cs = sf.colorSpace()
        ct = sf.colorTransfer()

        is_hdr = (
            cs == QVideoFrameFormat.ColorSpace.ColorSpace_BT2020
            or ct == QVideoFrameFormat.ColorTransfer.ColorTransfer_STD_B67
            or ct == QVideoFrameFormat.ColorTransfer.ColorTransfer_ST2084
        )
        if root_obj.property("isHdrStream") != is_hdr:
            root_obj.setProperty("isHdrStream", is_hdr)

        # Diferencia flujos 50 tbr (~20 ms/frame, como tdp HD) frente a 25 tbr (~40 ms/frame, como Cuatro HD)
        start_us = frame.startTime()
        if _last_frame_start > 0:
            delta_us = start_us - _last_frame_start
            if 5000 < delta_us < 100000:
                is_50tbr = delta_us < 28000
                if root_obj.property("is50TbrStream") != is_50tbr:
                    root_obj.setProperty("is50TbrStream", is_50tbr)
        _last_frame_start = start_us

    if video_out:
        video_out.videoFrameChanged.connect(_check_video_stream_props)

    exit_code = app.exec()

    # Limpieza ordenada antes de finalizar Python para evitar avisos de GC en Shiboken/PySide6
    if media_player:
        try:
            media_player.sourceChanged.disconnect(_reset_stream_state)
        except RuntimeError:
            pass
    if video_out:
        try:
            video_out.videoFrameChanged.disconnect(_check_video_stream_props)
        except RuntimeError:
            pass

    del media_player
    del gpu_shader_item
    del video_out
    del root_obj
    del engine
    del channel_model
    del screenshot_helper
    del cursor_helper
    gc.collect()
    del app

    sys.stdout.flush()
    sys.stderr.flush()
    os._exit(exit_code)


if __name__ == "__main__":
    main()
