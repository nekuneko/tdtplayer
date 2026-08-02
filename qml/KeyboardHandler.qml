// qml/KeyboardHandler.qml
import QtQuick

Item {
    id: root
    anchors.fill: parent
    
    // Forzamos la prioridad absoluta del foco en este nodo
    focus: true

    // Propiedades requeridas para inyectar las dependencias externas
    property var controller: null
    property var window: null
    property var channelNumPopup: null

    // Asegura recuperar el foco de forma automática al renderizar el componente
    Component.onCompleted: root.forceActiveFocus()

    // ===================================================================
    // 📺 MÓDULO 1: CONTROL RÁPIDO DE ZAPPING (CANALES)
    // ===================================================================
    Keys.onUpPressed: {
        if (root.controller) {
            root.controller.playChannel(root.controller.currentChannelIndex - 1);
        }
    }
    
    Keys.onDownPressed: {
        if (root.controller) {
            root.controller.playChannel(root.controller.currentChannelIndex + 1);
        }
    }
    
    // ===================================================================
    // 🔊 MÓDULO 2: CONTROL RÁPIDO DE AUDIO (VOLUMEN)
    // ===================================================================
    Keys.onLeftPressed: {
        if (root.controller) {
            root.controller.changeVolume(-5);
        }
    }
    
    Keys.onRightPressed: {
        if (root.controller) {
            root.controller.changeVolume(5);
        }
    }

    // ===================================================================
    // ⚙️ MÓDULO 3: ACCIONES AVANZADAS Y ATAJOS DE SISTEMA
    // ===================================================================
    Keys.onPressed: (event) => {
        if (!root.controller || !root.window || !root.channelNumPopup) return;

        switch (event.key) {
            case Qt.Key_Space:
                root.controller.togglePlayback();
                event.accepted = true;
                break;

            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (!root.channelNumPopup.opened) {
                    root.controller.forceResume();
                    event.accepted = true;
                }
                break;

            case Qt.Key_Escape:
                if (root.controller.isFullScreen && !root.channelNumPopup.opened) {
                    if (root.controller.sidebar && root.controller.sidebar.sidebarForceOpen) {
                        root.controller.sidebar.sidebarForceOpen = false;
                    } else {
                        root.window.visibility = Window.Windowed;
                        root.controller.isFullScreen = false;
                    }
                    event.accepted = true;
                }
                break;

            default:
                // Captura dinámica del teclado numérico (0 al 9) para el zapping directo
                if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                    if (!root.channelNumPopup.opened) {
                        root.channelNumPopup.openWithText(event.text);
                        event.accepted = true;
                    }
                }
                break;
        }
    }
}
