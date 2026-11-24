// qml/KeyboardHandler.qml
import QtQuick

Item {
    id: root
    
    required property var controller
    required property var window
    required property var windowController
    required property var channelNumPopup

    Keys.onPressed: (event) => {
        if (root.channelNumPopup.opened) {
            return;
        }

        // Si la parrilla está activa, permitimos el cierre desde aquí si el foco se desvía
        if (window.epgGridOverlayItem && window.epgGridOverlayItem.visible) {
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_E) {
                window.epgGridOverlayItem.visible = false;
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

            case Qt.Key_P:
                if (root.windowController) {
                    root.windowController.togglePipMode();
                }
                event.accepted = true;
                break;

            case Qt.Key_S:
                if (typeof screenshotHelper !== "undefined") {
                    screenshotHelper.capture_frame(root.controller.osdChannelName);
                }
                event.accepted = true;
                break;

            case Qt.Key_Space:
                root.controller.togglePlayback();
                event.accepted = true;
                break;

            // 🚀 SOLUCCIÓN DEFINITIVA DE 0 MS: Conmutación de visibilidad sobre el buffer de la GPU
            case Qt.Key_E:
                if (!root.windowController || !root.windowController.isPipMode) {
                    if (window.epgGridOverlayItem) {
                        if (window.epgGridOverlayItem.visible) {
                            window.epgGridOverlayItem.visible = false;
                        } else {
                            window.epgGridOverlayItem.visible = true;
                            window.epgGridOverlayItem.forceActiveFocus();
                        }
                    }
                }
                event.accepted = true;
                break;

            case Qt.Key_Escape:
                if (root.windowController && root.windowController.isPipMode) {
                    root.windowController.togglePipMode();
                    event.accepted = true;
                    break;
                }
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
