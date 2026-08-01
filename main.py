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
    
    # 2. Forzar el backend multimedia nativo de FFmpeg en Qt6
    os.environ["QT_MEDIA_BACKEND"] = "ffmpeg"

    # 3. CORRECCIÓN DEL ENTLAZADO EN VAAPI INTEL
    # Configuramos las opciones de FFmpeg para forzar el desentrelazado por hardware
    os.environ["QT_MULTIMEDIA_FFMPEG_HWACCEL"] = "vaapi"
    os.environ["FFMPEG_HWACCEL_RECOV"] = "1"
    
    # Inyectamos el argumento para que el decodificador de VAAPI aplique desentrelazado automático
    os.environ["QT_MULTIMEDIA_FFMPEG_OPTIONS"] = "deint=auto" 

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
