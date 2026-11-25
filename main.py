# main.py
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
from PySide6.QtMultimedia import QMediaPlayer, QVideoSink  # noqa: E402
from PySide6.QtQml import QQmlApplicationEngine  # noqa: E402

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

    player = root_obj.findChild(QMediaPlayer)
    # En QML VideoOutput expone la propiedad 'videoSink' (QVideoSink)
    video_out = root_obj.findChild(QVideoSink)
    if video_out:
        screenshot_helper.set_video_sink(video_out)

    if sys.platform == "win32":
        from deinterlace_filter import WindowsDeinterlacer

        if player and video_out:
            app._win_deinterlacer = WindowsDeinterlacer(player, video_out)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
