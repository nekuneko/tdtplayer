// qml/VideoPlayerView.qml
import QtQuick
import QtMultimedia

FocusScope {
    id: scope
    
    // Propiedades requeridas
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
    
    // Capa 1: El contenedor del vídeo estricto
    Rectangle {
        id: videoContainer
        
        // SOLUCIÓN: Ocupa el 100% del tamaño que le asigne el main.qml de forma segura
        anchors.fill: parent 
        
        color: "black"

        Timer {
            id: mouseInactivityTimer
            interval: 500; running: true; repeat: false
            onTriggered: videoMouseTracker.cursorShape = Qt.BlankCursor
        }

        MouseArea {
            id: videoMouseTracker
            anchors.fill: parent; hoverEnabled: true; z: -1 
            onPositionChanged: { videoMouseTracker.cursorShape = Qt.ArrowCursor; mouseInactivityTimer.restart() }
        }
        
        VideoOutput {
            id: videoOutput
            anchors.fill: parent; fillMode: VideoOutput.PreserveAspectFit

            TapHandler {
                onDoubleTapped: {
                    window.visibility = controller.isFullScreen ? Window.Windowed : Window.FullScreen
                    controller.isFullScreen = !controller.isFullScreen
                }
            }

            // Zonas de interacción rápida (Hover)
            MouseArea {
                id: bottomEdgeArea
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: controller.isFullScreen ? 40 : 0; hoverEnabled: true
                onEntered: if (controller.isFullScreen) epgDrawerItem.epgForceOpen = true
            }

            MouseArea {
                id: leftEdgeSwipeArea
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: 50; hoverEnabled: true
                onEntered: { controller.openConfigAndCollapseOthers(); configSidebarItem.sidebarForceOpen = true }
            }
            
            MouseArea {
                id: rightEdgeSwipeArea
                anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: controller.isFullScreen ? 50 : 0; hoverEnabled: true
                onEntered: if (controller.isFullScreen) sidebarItem.sidebarForceOpen = true
            }

            // Capas invisibles de descarte para cerrar menús
            MouseArea {
                anchors.fill: parent; anchors.rightMargin: sidebarItem.width 
                visible: controller.isFullScreen && sidebarItem.sidebarForceOpen
                onClicked: sidebarItem.sidebarForceOpen = false
            }

            MouseArea {
                anchors.fill: parent; anchors.leftMargin: configSidebarItem.width 
                visible: configSidebarItem.visible
                onClicked: { configSidebarItem.sidebarForceOpen = false; controller.restorePanelsAfterConfig() }
            }

            // Estado del streaming
            Text {
                anchors.centerIn: parent
                text: controller.isVoluntarilyStopped ? "Stream Detenido\nPulse Espacio o Enter para reanudar" : "Sintonizando canal...\nCargando flujo de Tvheadend"
                color: controller.isVoluntarilyStopped ? "#94A3B8" : "#3B82F6"
                font.pointSize: controller.isFullScreen ? 18 : 14; font.bold: true
                horizontalAlignment: Text.AlignHCenter; lineHeight: 1.3
                visible: mediaPlayer.playbackState !== MediaPlayer.PlayingState
            }
            
            OsdPanel {
                id: osdPanel
                channelName: controller.osdChannelName; channelLogo: controller.osdChannelLogo
                channelNo: controller.osdChannelNo; isFullScreen: controller.isFullScreen; opacity: controller.osdPanelOpacity 
            }

            ClockWidget {
                id: clockWidget
                anchors.top: parent.top; anchors.right: parent.right 
                anchors.topMargin: controller.isFullScreen ? 40 : 20
                anchors.rightMargin: (sidebarItem.visible && controller.isFullScreen && sidebarItem.width > 0) ? (sidebarItem.width + 40) : (controller.isFullScreen ? 40 : 20)
                opacity: controller.clockOpacity 
                Behavior on anchors.rightMargin { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
            }
            
            VolumeIndicator { volumePercent: controller.currentVolumePercent; showOsd: controller.showVolumeOsd }        
        }
    }
}