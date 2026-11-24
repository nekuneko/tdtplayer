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

        HoverHandler {
            id: containerHover
        }

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

                if (scope.isPip || window.visibility === Window.Minimized || sidebarItem.visible || configSidebarItem.visible)
                    return;
                var epgHeight = controller.epgDrawer.height;
                var epgTopBoundary = videoContainer.height - epgHeight;

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

            // Arrastre nativo de ventana cuando estamos en modo PiP
            DragHandler {
                id: pipWindowDragger
                enabled: scope.isPip
                target: null
                onActiveChanged: {
                    if (active) {
                        scope.window.startSystemMove();
                    }
                }
            }

            TapHandler {
                id: videoGestureOrchestrator
                acceptedButtons: Qt.LeftButton
                gesturePolicy: TapHandler.WithinBounds

                onTapped: {
                    controller.togglePlayback();
                }

                onDoubleTapped: {
                    Qt.callLater(function () {
                        if (scope.isPip) {
                            scope.windowController.togglePipMode();
                            return;
                        }
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
                enabled: !scope.isPip && !epgDrawerItem.epgForceOpen && !sidebarItem.visible
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
                enabled: !scope.isPip && !epgDrawerItem.epgForceOpen && !configSidebarItem.visible
                onEntered: sidebarItem.sidebarForceOpen = true
            }

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: sidebarItem.width
                visible: !scope.isPip && sidebarItem.sidebarForceOpen
                onClicked: sidebarItem.sidebarForceOpen = false
            }

            MouseArea {
                anchors.fill: parent
                anchors.leftMargin: configSidebarItem.width
                visible: !scope.isPip && configSidebarItem.visible
                onClicked: {
                    configSidebarItem.sidebarForceOpen = false;
                    controller.restorePanelsAfterConfig();
                }
            }

            // Controles flotantes estilo Firefox cuando está en modo PiP
            Item {
                id: pipOverlayHud
                anchors.fill: parent
                visible: scope.isPip
                opacity: containerHover.hovered ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                // Botón superior derecho: Restaurar ventana normal
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 10
                    width: 32
                    height: 32
                    radius: 16
                    color: "#CC0F172A"
                    border.color: "#475569"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "⧉"
                        color: "#FFFFFF"
                        font.pixelSize: 15
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: scope.windowController.togglePipMode()
                    }
                }

                // Barra inferior centrada: Silenciar y Play/Pause
                Row {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 12
                    spacing: 12

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 17
                        color: "#CC0F172A"
                        border.color: "#475569"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: mediaPlayer.audioOutput && mediaPlayer.audioOutput.muted ? "🔇" : "🔊"
                            color: "#FFFFFF"
                            font.pixelSize: 14
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controller.toggleMute()
                        }
                    }

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 17
                        color: "#CC0F172A"
                        border.color: "#475569"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: mediaPlayer.playbackState === MediaPlayer.PlayingState ? "⏸" : "▶"
                            color: "#FFFFFF"
                            font.pixelSize: 13
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controller.togglePlayback()
                        }
                    }
                }

                // Esquina inferior derecha para redimensionar el PiP libremente
                MouseArea {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: 18
                    height: 18
                    cursorShape: Qt.SizeFDiagCursor
                    onPressed: scope.window.startSystemResize(Qt.RightEdge | Qt.BottomEdge)
                }
            }
        }
    }
}
