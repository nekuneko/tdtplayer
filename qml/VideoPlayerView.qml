// qml/VideoPlayerView.qml
import QtQuick
import QtQuick.Controls
import QtMultimedia

FocusScope {
    id: scope

    required property var window
    required property var windowController
    required property var controller
    required property var sidebarItem
    required property var epgDrawerItem
    required property var configSidebarItem
    required property var globalKeyboardHandlerItem

    property alias mediaPlayer: mediaPlayer
    readonly property bool isPip: Boolean(windowController && windowController.isPipMode)
    readonly property bool isUhdHdr: videoOutput.sourceRect.height > 1080

    function resetMouseCursor() {
        videoMouseTracker.cursorShape = scope.isPip ? Qt.OpenHandCursor : Qt.ArrowCursor;
        mouseInactivityTimer.restart();
    }

    MediaPlayer {
        id: mediaPlayer
        audioOutput: AudioOutput {}
        videoOutput: videoOutput
    }

    Rectangle {
        id: videoContainer
        anchors.fill: parent
        color: "black"
        border.color: scope.isPip ? "#334155" : "transparent"
        border.width: scope.isPip ? 1 : 0

        HoverHandler { id: containerHover }

        Timer {
            id: mouseInactivityTimer
            interval: scope.isPip ? 1500 : 500
            running: !controller.isVoluntarilyStopped && (controller.epgDrawer ? !controller.epgDrawer.epgForceOpen : true)
            repeat: false
            onTriggered: {
                if (!scope.isPip) {
                    videoMouseTracker.cursorShape = Qt.BlankCursor;
                }
            }
        }

        Connections {
            target: controller.epgDrawer
            function onEpgForceOpenChanged() { scope.resetMouseCursor(); }
        }

        MouseArea {
            id: videoMouseTracker
            anchors.fill: parent
            hoverEnabled: true
            z: -1

            onPositionChanged: {
                scope.resetMouseCursor();
                if (scope.isPip || window.visibility === Window.Minimized || sidebarItem.visible || configSidebarItem.visible)
                    return;

                var epgTopBoundary = videoContainer.height - controller.epgDrawer.height;
                if (videoMouseTracker.mouseY >= epgTopBoundary) {
                    controller.epgDrawer.epgForceOpen = true;
                } else if (videoMouseTracker.mouseY < (epgTopBoundary - 10)) {
                    controller.epgDrawer.epgForceOpen = false;
                }
            }
        }

        VideoOutput {
            id: videoOutput
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectFit
        }

        VideoGesturesLayer {
            anchors.fill: parent
            z: 2
            window: scope.window
            windowController: scope.windowController
            controller: scope.controller
            sidebarItem: scope.sidebarItem
            epgDrawerItem: scope.epgDrawerItem
            configSidebarItem: scope.configSidebarItem
            isPip: scope.isPip
        }

        PipOverlayHud {
            anchors.fill: parent
            z: 3
            visible: scope.isPip
            window: scope.window
            windowController: scope.windowController
            controller: scope.controller
            mediaPlayer: mediaPlayer
            isHovered: containerHover.hovered
        }
    }
}
