// qml/VideoPlayerView.qml
import QtQuick
import QtMultimedia

FocusScope {
    id: scope

    required property var window
    required property var controller
    required property var sidebarItem
    required property var epgDrawerItem
    required property var configSidebarItem
    required property var globalKeyboardHandlerItem

    property alias mediaPlayer: mediaPlayer

    function resetMouseCursor() {
        videoMouseTracker.cursorShape = Qt.ArrowCursor;
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

        Timer {
            id: mouseInactivityTimer
            interval: 500
            running: !controller.isVoluntarilyStopped && (controller.epgDrawer ? !controller.epgDrawer.epgForceOpen : true)
            repeat: false
            onTriggered: videoMouseTracker.cursorShape = Qt.BlankCursor
        }

        Connections {
            target: controller.epgDrawer
            function onEpgForceOpenChanged() {
                scope.resetMouseCursor();
            }
        }

        // Rastreador de movimiento y zonas de control
        MouseArea {
            id: videoMouseTracker
            anchors.fill: parent
            hoverEnabled: true
            z: -1

            onPositionChanged: {
                scope.resetMouseCursor();

                if (window.visibility === Window.Minimized || sidebarItem.visible || configSidebarItem.visible)
                    return;
                var epgHeight = controller.epgDrawer.height;
                var epgTopBoundary = videoContainer.height - epgHeight;

                if (videoMouseTracker.mouseY >= epgTopBoundary) {
                    controller.epgDrawer.epgForceOpen = true;
                } else if (videoMouseTracker.mouseY < (epgTopBoundary - 10)) {
                    // 🚀 CIERRE POR CONTACTO REAL: Cuando el ratón vuelve a la zona del reproductor de vídeo, se oculta el drawer
                    controller.epgDrawer.epgForceOpen = false;
                }
            }
        }

        VideoOutput {
            id: videoOutput
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectFit

            TapHandler {
                id: videoGestureOrchestrator
                acceptedButtons: Qt.LeftButton
                gesturePolicy: TapHandler.WithinBounds

                onTapped: {
                    controller.togglePlayback();
                }

                onDoubleTapped: {
                    Qt.callLater(function () {
                        if (window.visibility === Window.FullScreen) {
                            window.visibility = Window.Windowed;
                            controller.isFullScreen = false;
                        } else {
                            window.visibility = Window.FullScreen;
                            controller.isFullScreen = true;
                        }
                    });
                }
            }

            WheelHandler {
                id: mouseWheelZapper
                orientation: Qt.Vertical
                onWheel: event => {
                    if (event.angleDelta.y > 0) {
                        controller.playChannel(controller.currentChannelIndex - 1);
                    } else if (event.angleDelta.y < 0) {
                        controller.playChannel(controller.currentChannelIndex + 1);
                    }
                }
            }

            MouseArea {
                id: leftEdgeSwipeArea
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 50
                hoverEnabled: true
                enabled: !epgDrawerItem.epgForceOpen && !sidebarItem.visible
                onEntered: {
                    controller.openConfigAndCollapseOthers();
                    configSidebarItem.sidebarForceOpen = true;
                }
            }

            MouseArea {
                id: rightEdgeSwipeArea
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 50
                hoverEnabled: true
                enabled: !epgDrawerItem.epgForceOpen && !configSidebarItem.visible
                onEntered: sidebarItem.sidebarForceOpen = true
            }

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: sidebarItem.width
                visible: sidebarItem.sidebarForceOpen
                onClicked: sidebarItem.sidebarForceOpen = false
            }

            MouseArea {
                anchors.fill: parent
                anchors.leftMargin: configSidebarItem.width
                visible: configSidebarItem.visible
                onClicked: {
                    configSidebarItem.sidebarForceOpen = false;
                    controller.restorePanelsAfterConfig();
                }
            }
        }
    }
}
