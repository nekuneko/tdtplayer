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

            // Gestor de gestos unificado en caliente
            TapHandler {
                id: videoGestureHandler
                gesturePolicy: TapHandler.ReleaseWithinBounds
                
                onTapped: {
                    if (videoGestureHandler.tapCount === 2) {
                        // 1. Conmutamos la pantalla completa de forma instantánea
                        window.visibility = controller.isFullScreen ? Window.Windowed : Window.FullScreen
                        controller.isFullScreen = !controller.isFullScreen
                        
                        // 2. SOLUCIÓN: Reanudamos el buffer de vídeo inmediatamente. 
                        // Al no vaciar la URL en el controlador, la reproducción continúa sin cortes de red.
                        controller.cancelAccidentalPause()
                    } 
                    else if (videoGestureHandler.tapCount === 1) {
                        // Respuesta inmediata al hacer un solo clic
                        controller.togglePlayback()
                    }
                }
            }

            // Zapping mediante la rueda del ratón
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

            // 🛡️ SENSOR INFERIOR (EPG): Solo se activa si las barras izquierda y derecha están CERRADAS
            MouseArea {
                id: bottomEdgeArea
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 40
                hoverEnabled: true
                enabled: !sidebarItem.visible && !configSidebarItem.visible
                onEntered: epgDrawerItem.epgForceOpen = true
            }

            // 🛡️ SENSOR IZQUIERDO (Configuración): Solo se activa si el EPG inferior y la lista de canales están CERRADOS
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
            
            // 🛡️ SENSOR DERECHO (Lista de canales): Solo se activa si el EPG inferior y la configuración están CERRADOS
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

            // Dentro de qml/VideoPlayerView.qml (Componente Text central)
            Text {
                id: streamStatusText
                anchors.centerIn: parent
                color: controller.isVoluntarilyStopped ? "#94A3B8" : "#3B82F6"
                font.pointSize: controller.isFullScreen ? 18 : 14
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.3
                
                // Propiedad interna que filtra el parpadeo del cartel
                text: controller.isVoluntarilyStopped 
                      ? "Stream Detenido\nPulse Espacio o Enter para reanudar" 
                      : "Sintonizando canal...\nCargando flujo de Tvheadend"

                // El cartel de pausa solo se muestra si el motor realmente no está reproduciendo
                // Y si la propiedad 'isVoluntarilyStopped' sigue activa tras el filtro del temporizador
                visible: (mediaPlayer.playbackState !== MediaPlayer.PlayingState) && textDebounceTimer.canShowText

                // ⏱️ FILTRO DE PARPADEO: Espera 200ms para confirmar la visualización del texto.
                // Si haces doble clic, la pausa se cancela antes de que termine el tiempo y el cartel no aparece.
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
