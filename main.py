# main.py
import sys
import os
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from channel_model import ChannelModel

def main():
    # 1. Fuerza el backend EGL para la GPU Intel
    os.environ["QT_XCB_GL_INTEGRATION"] = "xcb_egl"
    os.environ["QML_XHR_ALLOW_FILE_READ"] = "1"
    
    # 2. Tu filtro de desentrelazado yadif que ya teníamos
    os.environ["QT_MULTIMEDIA_FFMPEG_FILTERS"] = "yadif=mode=send_frame:parity=auto:deint=interlaced"

    # NUEVO: CORRECCIÓN PARA EL ERROR HEVC INTEL (Fuerza la recuperación de hilos y limpia errores de decodificación)
    os.environ["FFMPEG_HWACCEL_RECOV"] = "1"
    os.environ["QT_MULTIMEDIA_FFMPEG_HWACCEL"] = "vaapi"

    #os.environ["QT_MULTIMEDIA_FFMPEG_OPTIONS"] = "probesize=5000000;analyzeduration=1000000;fflags=+nobuffer+discardcorrupt"
    
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    def handle_qml_warnings(warnings):
        for warning in warnings:
            print(f"Error en QML: {warning.toString()}", file=sys.stderr)
    engine.warnings.connect(handle_qml_warnings)

    channel_model = ChannelModel()
    engine.rootContext().setContextProperty("channelModel", channel_model)

    qml_file = os.path.join(os.path.dirname(__file__), "main.qml")
    engine.load(qml_file)

    if not engine.rootObjects():
        print("Error crítico: No se pudieron cargar los objetos raíz de QML.", file=sys.stderr)
        sys.exit(-1)

    sys.exit(app.exec())

if __name__ == "__main__":
    main()
