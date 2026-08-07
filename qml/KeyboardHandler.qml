// KeyboardHandler.qml
import QtQuick

Item {
    id: root
    
    required property var controller
    required property var window
    required property var channelNumPopup

    Keys.onPressed: (event) => {
        if (root.channelNumPopup.opened) {
            return;
        }

        // Si la parrilla está activa, permitimos el cierre desde aquí si el foco se desvía
        if (window.epgGridOverlayItem && window.epgGridOverlayItem.visible) {
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_E) {
                window.epgGridOverlayItem.closeRequested();
                event.accepted = true;
                return;
            }
        }

        switch (event.key) {
            case Qt.Key_Up:
                root.controller.playChannel(root.controller.currentChannelIndex - 1);
                event.accepted = true;
                break;
                
            case Qt.Key_Down:
                root.controller.playChannel(root.controller.currentChannelIndex + 1);
                event.accepted = true;
                break;

            case Qt.Key_Left:
                root.controller.changeVolume(-5);
                event.accepted = true;
                break;
                
            case Qt.Key_Right:
                root.controller.changeVolume(5);
                event.accepted = true;
                break;

            case Qt.Key_M:
                root.controller.toggleMute();
                event.accepted = true;
                break;

            // 🚀 SOLUCIÓN ESTRUCTURAL: Conmutación directa usando la propiedad expuesta en la ventana raíz
            case Qt.Key_E:
                if (window.epgGridOverlayItem && window.epgGridOverlayItem.visible) {
                    window.epgGridOverlayItem.closeRequested();
                } else {
                    // Acceso directo y blindado al Loader expuesto de main.qml
                    window.epgGridOverlayLoaderItemActive = true;
                }
                event.accepted = true;
                break;

            case Qt.Key_Escape:
                if (root.controller.sidebar && root.controller.sidebar.sidebarForceOpen) {
                    root.controller.sidebar.sidebarForceOpen = false;
                }
                if (root.controller.epgDrawer && root.controller.epgDrawer.epgForceOpen) {
                    root.controller.epgDrawer.epgForceOpen = false;
                }
                event.accepted = true;
                break;

            default:
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
