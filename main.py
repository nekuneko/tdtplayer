# main.py
import os
import sys

# 🚀 MOTOR DE SINCRONIZACIÓN NATIVO PARA PERFIL 'PASS' (MPEG-TS EN BRUTO)
# Ampliamos el análisis de cabeceras para que Qt Multimedia asimile el flujo de BeMad HD
# junto con todas sus pistas síncronas (EPG, audios alternos y teletexto) de una sola pasada.
os.environ["QT_MULTIMEDIA_FFMPEG_OPTIONS"] = (
    "probesize=20000000;analyzeduration=10000000"
)

# Fuerza el backend de integración EGL estable para la GPU Intel en servidores X11
os.environ["QT_XCB_GL_INTEGRATION"] = "xcb_egl"

# Permitir explícitamente que los objetos XMLHttpRequest de QML lean archivos locales
os.environ["QML_XHR_ALLOW_FILE_READ"] = "1"

# Forzar el uso estricto de la API de aceleración por hardware de Intel (VA-API)
os.environ["QT_MULTIMEDIA_FFMPEG_HWACCEL"] = "vaapi"

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from channel_model import ChannelModel


def main():
    # Identificadores estáticos obligatorios para habilitar el componente Settings en QML
    QGuiApplication.setOrganizationName("TvheadendNative")
    QGuiApplication.setOrganizationDomain("tvheadend.native")
    QGuiApplication.setApplicationName("TvheadendNativePlayer")

    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    # Asegura que Qt6 encuentre tus nuevos archivos .qml modularizados de la subcarpeta qml/
    base_dir = os.path.dirname(__file__)
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

    context = engine.rootContext()
    context.setContextProperty("channelModel", channel_model)

    qml_file = os.path.join(base_dir, "main.qml")
    engine.load(qml_file)

    if not engine.rootObjects():
        print(
            "Error crítico: No se pudieron cargar los objetos raíz de QML.",
            file=sys.stderr,
        )
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
