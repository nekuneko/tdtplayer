# main.py
import sys
import os
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from channel_model import ChannelModel

def main():
    os.environ["QT_XCB_GL_INTEGRATION"] = "xcb_egl"
    # SOLUCIÓN AL ERROR DE XMLHTTPREQUEST: Permite leer el archivo .m3u local
    os.environ["QML_XHR_ALLOW_FILE_READ"] = "1"
    # FORZAR DESENTRELAZADO EN EL BACKEND DE FFMPEG DE QT6
    os.environ["QT_MULTIMEDIA_FFMPEG_FILTERS"] = "yadif=mode=send_frame:parity=auto:deint=interlaced"
    
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
