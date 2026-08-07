# main.py
import sys
import os
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, QQmlContext
from channel_model import ChannelModel

def main():
    os.environ["QT_MULTIMEDIA_FFMPEG_OPTIONS"] = "probesize=5000000;analyzeduration=1000000;fflags=+nobuffer+discardcorrupt"
    
    # 1. Fuerza el backend EGL para la GPU Intel
    os.environ["QT_XCB_GL_INTEGRATION"] = "xcb_egl"
    os.environ["QML_XHR_ALLOW_FILE_READ"] = "1"
    
    # 2. Forzar el backend multimedia nativo de FFmpeg en Qt6
    os.environ["QT_MEDIA_BACKEND"] = "ffmpeg"

    # 3. CORRECCIÓN DEL ENTLAZADO EN VAAPI INTEL
    os.environ["QT_MULTIMEDIA_FFMPEG_HWACCEL"] = "vaapi"
    os.environ["FFMPEG_HWACCEL_RECOV"] = "1"

    # 📝 AÑADIR AQUÍ: Identificadores para habilitar el componente Settings en QML
    QGuiApplication.setOrganizationName("TvheadendNative")
    QGuiApplication.setOrganizationDomain("tvheadend.native")
    QGuiApplication.setApplicationName("TvheadendNativePlayer")
    
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    # 🚀 OPTIMIZACIÓN DE RUTAS: Asegura que Qt6 encuentre tus nuevos archivos .qml modularizados
    base_dir = os.path.dirname(__file__)
    qml_dir = os.path.join(base_dir, "qml") if os.path.exists(os.path.join(base_dir, "qml")) else base_dir
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
        print("Error crítico: No se pudieron cargar los objetos raíz de QML.", file=sys.stderr)
        sys.exit(-1)

    sys.exit(app.exec())

if __name__ == "__main__":
    main()
