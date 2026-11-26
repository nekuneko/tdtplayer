// qml/KeyboardHandler.qml
import QtQuick

Item {
    id: root

    required property var controller
    required property var window
    required property var windowController
    required property var channelNumPopup

    readonly property bool isSidebarBrowsing: Boolean(root.controller.sidebar && root.controller.sidebar.visible && root.controller.sidebar.sidebarForceOpen)

    function pageStep() {
        if (root.controller.sidebar && root.controller.sidebar.visibleRowsCount) {
            return Math.max(4, root.controller.sidebar.visibleRowsCount() - 1);
        }
        return 8;
    }

    function stepChannel(delta) {
        if (!root.controller.model)
            return;
        var count = root.controller.model.rowCount();
        if (count === 0)
            return;
        var rawTarget = root.controller.currentChannelIndex + delta;
        var wrapped = ((rawTarget % count) + count) % count;

        if (root.isSidebarBrowsing) {
            root.controller.previewChannel(wrapped);
        } else {
            root.controller.playChannel(wrapped);
        }
    }

    Keys.onPressed: event => {
        if (root.channelNumPopup.opened)
            return;

        if (window.epgGridOverlayItem && window.epgGridOverlayItem.visible) {
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_E) {
                window.epgGridOverlayItem.visible = false;
                event.accepted = true;
                return;
            }
        }

        switch (event.key) {
            case Qt.Key_Up:
                root.stepChannel(-1);
                event.accepted = true;
                break;

            case Qt.Key_Down:
                root.stepChannel(1);
                event.accepted = true;
                break;

            case Qt.Key_PageUp:
                root.stepChannel(-root.pageStep());
                event.accepted = true;
                break;

            case Qt.Key_PageDown:
                root.stepChannel(root.pageStep());
                event.accepted = true;
                break;

            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (root.isSidebarBrowsing) {
                    root.controller.playChannel(root.controller.currentChannelIndex, true);
                    event.accepted = true;
                }
                break;

            case Qt.Key_Left:
                root.controller.changeVolume(-5);
                event.accepted = true;
                break;

            case Qt.Key_Right:
                root.controller.changeVolume(5);
                event.accepted = true;
                break;

            case Qt.Key_Space:
                root.controller.togglePlayback();
                event.accepted = true;
                break;

            case Qt.Key_M:
                root.controller.toggleMute();
                event.accepted = true;
                break;

            case Qt.Key_S:
                if (typeof screenshotHelper !== "undefined") {
                    screenshotHelper.capture_frame(root.controller.osdChannelName);
                }
                event.accepted = true;
                break;

            case Qt.Key_P:
                if (root.windowController) {
                    root.windowController.togglePipMode();
                }
                event.accepted = true;
                break;

            case Qt.Key_E:
                if ((!root.windowController || !root.windowController.isPipMode) && window.epgGridOverlayItem) {
                    var nextVisible = !window.epgGridOverlayItem.visible;
                    window.epgGridOverlayItem.visible = nextVisible;
                    if (nextVisible) {
                        window.epgGridOverlayItem.forceActiveFocus();
                    }
                }
                event.accepted = true;
                break;

            case Qt.Key_F:
            case Qt.Key_F11:
                if (root.windowController && root.windowController.isPipMode) {
                    root.windowController.togglePipMode(true);
                } else {
                    var toFullScreen = root.window.visibility !== Window.FullScreen;
                    root.window.visibility = toFullScreen ? Window.FullScreen : Window.Windowed;
                }
                event.accepted = true;
                break;


            case Qt.Key_Escape:
                root.controller.cancelPendingZapping();
                if (root.controller.sidebar && root.controller.sidebar.sidebarForceOpen) {
                    root.controller.sidebar.sidebarForceOpen = false;
                }
                if (root.controller.epgDrawer && root.controller.epgDrawer.epgForceOpen) {
                    root.controller.epgDrawer.epgForceOpen = false;
                }
                event.accepted = true;
                break;

            default:
                if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9 && !root.channelNumPopup.opened) {
                    root.channelNumPopup.openWithText(event.text);
                    event.accepted = true;
                }
                break;
        }
    }
}
