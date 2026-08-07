// KeyboardHandler.qml
import QtQuick

Item {
    id: root
    
    required property var controller
    required property var window
    required property var channelNumPopup

    Keys.onPressed: (event) => {
        // Si el OSD numérico está absorbiendo caracteres, delegamos el evento
        if (root.channelNumPopup.opened) {
            return;
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

            // 🚀 MAPEO DE LA TECLA M PARA SILENCIADO
            case Qt.Key_M:
                root.controller.toggleMute();
                event.accepted = true;
                break;

            case Qt.Key_Space:
            case Qt.Key_Return:
            case Qt.Key_Enter:
                root.controller.togglePlayback();
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
