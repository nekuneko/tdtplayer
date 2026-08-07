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
        videoMouseTracker.cursorShape = Qt.ArrowCursor
        mouseInactivityTimer.restart()
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
                scope.resetMouseCursor()
            }
        }

        // Rastreador de movimiento y zonas del EPG (en el fondo)
        MouseArea {
            id: videoMouseTracker
            anchors.fill: parent
            hoverEnabled: true
            z: -1 

            onPositionChanged: { 
                scope.resetMouseCursor()

                if (sidebarItem.visible || configSidebarItem.visible) return

                var epgHeight = controller.epgDrawer.height
                var epgTopBoundary = videoContainer.height - epgHeight

                if (videoMouseTracker.mouseY >= epgTopBoundary) {
                    controller.epgDrawer.epgForceOpen = true
                } else if (videoMouseTracker.mouseY < (epgTopBoundary - 10)) {
                    controller.epgDrawer.epgForceOpen = false
                }
            }
        }
        
        VideoOutput {
            id: videoOutput
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectFit

            // 🚀 ARQUITECTURA MAESTRA UNIFICADA: Un solo TapHandler para filtrar y separar órdenes sin colisiones
            TapHandler {
                id: videoGestureOrchestrator
                acceptedButtons: Qt.LeftButton
                
                // Exigimos que el gesto se complete estrictamente dentro de los límites visuales
                gesturePolicy: TapHandler.WithinBounds

                // Se ejecuta EXCLUSIVAMENTE cuando Qt6 confirma que es un único clic aislado
                onTapped: {
                    controller.togglePlayback()
                }

                // Se ejecuta EXCLUSIVAMENTE al hacer doble clic rápido, anulando por completo el disparo de onTapped
                onDoubleTapped: {
                    window.visibility = controller.isFullScreen ? Window.Windowed : Window.FullScreen
                    controller.isFullScreen = !controller.isFullScreen
                }
            }

            WheelHandler {
                id: mouseWheelZapper
                orientation: Qt.Vertical
                onWheel: (event) => {
                    if (event.angleDelta.y > 0) {
                        controller.playChannel(controller.currentChannelIndex - 1)
                    } else if (event.angleDelta.y < 0) {
                        controller.playChannel(controller.currentChannelIndex + 1)
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
                    controller.openConfigAndCollapseOthers()
                    configSidebarItem.sidebarForceOpen = true 
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
                    configSidebarItem.sidebarForceOpen = false
                    controller.restorePanelsAfterConfig() 
                }
            }

            Text {
                id: streamStatusText
                anchors.centerIn: parent
                color: controller.isVoluntarilyStopped ? "#94A3B8" : "#3B82F6"
                font.pointSize: controller.isFullScreen ? 18 : 14
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.3
                text: controller.isVoluntarilyStopped 
                      ? "Stream Detenido\nPulse Espacio o Enter para reanudar" 
                      : "Sintonizando canal...\nCargando flujo de Tvheadend"
                visible: (mediaPlayer.playbackState !== MediaPlayer.PlayingState) && textDebounceTimer.canShowText

                property Timer textDebounceTimer: Timer {
                    id: textDebounceTimer
                    property bool canShowText: false
                    interval: 200
                    running: controller.isVoluntarilyStopped && (mediaPlayer.playbackState !== MediaPlayer.PlayingState)
                    repeat: false
                    onRunningChanged: {
                        if (!running && controller.isVoluntarilyStopped) {
                            canShowText = true
                        } else if (!controller.isVoluntarilyStopped) {
                            canShowText = false
                        }
                    }
                }
            }
            
            ClockWidget {
                id: clockWidget
                anchors.top: parent.top
                anchors.right: parent.right 
                anchors.topMargin: controller.isFullScreen ? 40 : 20
                anchors.rightMargin: (sidebarItem.visible && sidebarItem.width > 0) ? (sidebarItem.width + 40) : (controller.isFullScreen ? 40 : 20)
                opacity: controller.clockOpacity 
                Behavior on anchors.rightMargin { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            
            VolumeIndicator { 
                volumePercent: controller.currentVolumePercent
                showOsd: controller.showVolumeOsd 
            }        
        }
    }
}
