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

    TapHandler {
        id: videoGestureOrchestrator
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.WithinBounds

        onTapped: root.controller.togglePlayback()

        onDoubleTapped: {
            Qt.callLater(function () {
                if (root.isPip) {
                    root.windowController.togglePipMode();
                    return;
                }
                if (root.window.visibility === Window.FullScreen) {
                    root.window.visibility = Window.Windowed;
                    root.controller.isFullScreen = false;
                } else {
                    root.window.visibility = Window.FullScreen;
                    root.controller.isFullScreen = true;
                }
            });
        }
    }

    WheelHandler {
        id: mouseWheelZapper
        orientation: Qt.Vertical
        onWheel: event => {
            if (event.angleDelta.y > 0) {
                root.controller.playChannel(root.controller.currentChannelIndex - 1);
            } else if (event.angleDelta.y < 0) {
                root.controller.playChannel(root.controller.currentChannelIndex + 1);
            }
        }
    }

    MouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 50
        hoverEnabled: true
        enabled: !root.isPip && !root.epgDrawerItem.epgForceOpen && !root.sidebarItem.visible
        onEntered: {
            root.controller.openConfigAndCollapseOthers();
            root.configSidebarItem.sidebarForceOpen = true;
        }
    }

    MouseArea {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 50
        hoverEnabled: true
        enabled: !root.isPip && !root.epgDrawerItem.epgForceOpen && !root.configSidebarItem.visible
        onEntered: root.sidebarItem.sidebarForceOpen = true
    }

    MouseArea {
        anchors.fill: parent
        anchors.rightMargin: root.sidebarItem.width
        visible: !root.isPip && root.sidebarItem.sidebarForceOpen
        onClicked: root.sidebarItem.sidebarForceOpen = false
    }

    MouseArea {
        anchors.fill: parent
        anchors.leftMargin: root.configSidebarItem.width
        visible: !root.isPip && root.configSidebarItem.visible
        onClicked: {
            root.configSidebarItem.sidebarForceOpen = false;
            root.controller.restorePanelsAfterConfig();
        }
    }
}
