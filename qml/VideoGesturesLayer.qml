// qml/VideoGesturesLayer.qml
import QtQuick

Item {
    id: root

    required property var window
    required property var windowController
    required property var controller
    required property var sidebarItem
    required property var epgDrawerItem
    required property var configSidebarItem
    required property bool isPip

    readonly property bool isSidebarOpen: !root.isPip && root.sidebarItem.sidebarForceOpen
    readonly property bool isConfigOpen: !root.isPip && root.configSidebarItem.visible
    readonly property real epgMarginOffset: (typeof appTheme !== "undefined" && appTheme) ? appTheme.px(24) : 24

    // Arrastre nativo de ventana cuando estamos en modo PiP
    DragHandler {
        id: pipWindowDragger
        enabled: root.isPip
        target: null
        onActiveChanged: {
            if (active) {
                root.window.startSystemMove();
            }
        }
    }

    Timer {
        id: singleClickTimer
        interval: 220
        repeat: false
        onTriggered: {
            if (!root.epgDrawerItem.visible && !root.sidebarItem.visible && !root.configSidebarItem.visible) {
                root.controller.togglePlayback();
            }
        }
    }

    MouseArea {
        id: videoClickArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        propagateComposedEvents: true

        onClicked: singleClickTimer.restart()

        onDoubleClicked: {
            singleClickTimer.stop();
            if (root.isPip) {
                root.windowController.togglePipMode();
                return;
            }
            var toFullScreen = root.window.visibility !== Window.FullScreen;
            root.window.visibility = toFullScreen ? Window.FullScreen : Window.Windowed;
        }
    }

    WheelHandler {
        id: mouseWheelZapper
        orientation: Qt.Vertical
        enabled: !root.isPip
        onWheel: event => {
            var delta = event.angleDelta.y > 0 ? -1 : 1;
            root.controller.playChannel(root.controller.currentChannelIndex + delta);
        }
    }

    // Único handler unificado para cerrar cualquier sidebar al hacer clic fuera
    MouseArea {
        id: backdropDismissArea
        anchors.fill: parent
        anchors.leftMargin: root.isConfigOpen ? root.configSidebarItem.width : 0
        anchors.rightMargin: root.isSidebarOpen ? root.sidebarItem.width : 0
        anchors.bottomMargin: root.epgDrawerItem.visible ? (root.epgDrawerItem.height + root.epgMarginOffset) : 0
        visible: root.isSidebarOpen || root.isConfigOpen

        onClicked: {
            if (root.isSidebarOpen) {
                root.sidebarItem.sidebarForceOpen = false;
            }
            if (root.isConfigOpen) {
                root.configSidebarItem.sidebarForceOpen = false;
                root.controller.restorePanelsAfterConfig();
            }
        }
    }
}
