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
            running: true
            repeat: false
            onTriggered: videoMouseTracker.cursorShape = Qt.BlankCursor
        }

        MouseArea {
            id: videoMouseTracker
            anchors.fill: parent
            hoverEnabled: true
            z: -1 
            onPositionChanged: { 
                videoMouseTracker.cursorShape = Qt.ArrowCursor
                mouseInactivityTimer.restart() 
            }
        }
        
        VideoOutput {
            id: videoOutput
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectFit

            TapHandler {
                onDoubleTapped: {
                    window.visibility = controller.isFullScreen ? Window.Windowed : Window.FullScreen
                    controller.isFullScreen = !controller.isFullScreen
                }
            }

            // 🚀 NUEVA FUNCIÓN: Zapping mediante la rueda del ratón (Milisegundo 0)
            WheelHandler {
                id: mouseWheelZapper
                // Intercepta únicamente los desplazamientos en el eje vertical
                orientation: Qt.Vertical
                
                onWheel: (event) => {
                    // event.angleDelta.y devuelve valores positivos al rodar hacia arriba y negativos hacia abajo
                    if (event.angleDelta.y > 0) {
                        // Rueda hacia ARRIBA: Sintoniza el canal anterior (Index - 1)
                        controller.playChannel(controller.currentChannelIndex - 1)
                    } else if (event.angleDelta.y < 0) {
                        // Rueda hacia ABAJO: Sintoniza el canal siguiente (Index + 1)
                        controller.playChannel(controller.currentChannelIndex + 1)
                    }
                }
            }

            MouseArea {
                id: bottomEdgeArea
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 40
                hoverEnabled: true
                onEntered: epgDrawerItem.epgForceOpen = true
            }

            MouseArea {
                id: leftEdgeSwipeArea
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 50
                hoverEnabled: true
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
                anchors.centerIn: parent
                text: controller.isVoluntarilyStopped ? "Stream Detenido\nPulse Espacio o Enter para reanudar" : "Sintonizando canal...\nCargando flujo de Tvheadend"
                color: controller.isVoluntarilyStopped ? "#94A3B8" : "#3B82F6"
                font.pointSize: controller.isFullScreen ? 18 : 14
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.3
                visible: mediaPlayer.playbackState !== MediaPlayer.PlayingState
            }
            
            OsdPanel {
                id: osdPanel
                channelName: controller.osdChannelName
                channelLogo: controller.osdChannelLogo
                channelNo: controller.osdChannelNo
                isFullScreen: controller.isFullScreen
                opacity: controller.osdPanelOpacity 
            }

            ClockWidget {
                id: clockWidget
                anchors.top: parent.top
                anchors.right: parent.right 
                anchors.topMargin: controller.isFullScreen ? 40 : 20
                anchors.rightMargin: (sidebarItem.visible && sidebarItem.width > 0) ? (sidebarItem.width + 40) : (controller.isFullScreen ? 40 : 20)
                opacity: (controller.osdPanelOpacity > 0.0 || sidebarItem.visible || epgDrawerItem.visible) ? 1.0 : 0.0
                z: 10
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
