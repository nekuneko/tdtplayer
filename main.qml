// main.qml
import QtQuick
import QtQuick.Controls
import QtMultimedia
import QtQuick.Dialogs
import "qml"

ApplicationWindow {
    id: window
    width: 1024
    height: 768
    visible: true
    title: "Tvheadend Native Player"

    // Instancia de nuestro orquestador lógico
    PlaybackController {
        id: ctrl
        model: channelModel
        mediaPlayer: mediaPlayer
        sidebar: sidebar
        epgDrawer: epgDrawer
    }

    // Inyección del capturador de teclado desacoplado
    KeyboardHandler {
        id: globalKeyboardHandler // 👈 NUEVO: Añadimos este ID
        controller: ctrl
        window: window
        channelNumPopup: channelNumPopup
        focus: true // 👈 NUEVO: Forzamos bandera inicial
    }

    FocusScope {
        id: mainFocusScope
        anchors.fill: parent

        MediaPlayer {
            id: mediaPlayer
            audioOutput: AudioOutput {}
            videoOutput: videoOutput
        }
        
        // Capa 1: El contenedor del vídeo estricto
        Rectangle {
            id: videoContainer
            anchors.left: parent.left
            // 🛠️ REPARADO: El vídeo ahora ignora la barra lateral si está en pantalla completa
            anchors.right: (sidebar.visible && !ctrl.isFullScreen) ? sidebar.left : parent.right
            anchors.top: parent.top
            anchors.bottom: (epgDrawer.visible && !ctrl.isFullScreen) ? epgDrawer.top : parent.bottom
            color: "black"

            VideoOutput {
                id: videoOutput
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectFit

                TapHandler {
                    onDoubleTapped: {
                        window.visibility = ctrl.isFullScreen ? Window.Windowed : Window.FullScreen;
                        ctrl.isFullScreen = !ctrl.isFullScreen;
                    }
                }

                MouseArea {
                    id: bottomEdgeArea
                    anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                    height: ctrl.isFullScreen ? 40 : 0 
                    hoverEnabled: true
                    onEntered: { if (ctrl.isFullScreen) epgDrawer.epgForceOpen = true }
                }

                // ❌ (ELIMINADO DE AQUÍ EL EpgDrawer)

                MouseArea {
                    id: rightEdgeSwipeArea
                    anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                    width: ctrl.isFullScreen ? 50 : 0 
                    hoverEnabled: true
                    onEntered: { if (ctrl.isFullScreen) sidebar.sidebarForceOpen = true }
                }

                MouseArea {
                    anchors.fill: parent; anchors.rightMargin: sidebar.width
                    visible: ctrl.isFullScreen && sidebar.sidebarForceOpen
                    onClicked: sidebar.sidebarForceOpen = false
                }

                Text {
                    anchors.centerIn: parent
                    text: ctrl.isVoluntarilyStopped 
                          ? "Stream Detenido\nPulse Espacio o Enter para reanudar" 
                          : "Sintonizando canal...\nCargando flujo de Tvheadend"
                    color: ctrl.isVoluntarilyStopped ? "#94A3B8" : "#3B82F6"
                    font.pointSize: ctrl.isFullScreen ? 18 : 14; font.bold: true
                    horizontalAlignment: Text.AlignHCenter; lineHeight: 1.3
                    visible: mediaPlayer.playbackState !== MediaPlayer.PlayingState
                }
                
                OsdPanel {
                    id: osdPanel
                    channelName: ctrl.osdChannelName
                    channelLogo: ctrl.osdChannelLogo
                    channelNo: ctrl.osdChannelNo
                    isFullScreen: ctrl.isFullScreen
                    opacity: ctrl.osdPanelOpacity 
                }
                
                VolumeIndicator {
                    volumePercent: ctrl.currentVolumePercent
                    showOsd: ctrl.showVolumeOsd
                }        
            } // Fin de VideoOutput
        } // Fin de videoContainer

        EpgDrawer {
            id: epgDrawer
            channelName: ctrl.osdChannelName
            channelNo: ctrl.osdChannelNo
            hoveredChannelName: ctrl.osdHoveredChannelName
            epgTitle: ctrl.epgTitle
            epgDescription: ctrl.epgDescription
            isFullScreen: ctrl.isFullScreen
            sidebarItem: sidebar 
            z: 1 
            
            // 👇 NUEVO: Temporizador interno e independiente para la persiana del EPG
            Timer {
                id: keyboardEpgTimer
                interval: 3000 // Se esconde tras 3 segundos de inactividad del teclado
                onTriggered: epgDrawer.epgForceOpen = false
            }

            // 👇 NUEVO: Escuchamos de forma segura la señal del controlador
            Connections {
                target: ctrl
                function onChannelZappedByKeyboard() {
                    if (ctrl.isFullScreen) {
                        epgDrawer.epgForceOpen = true; // Abre la persiana de inmediato
                        keyboardEpgTimer.restart();     // Reinicia los 3 segundos de cortesía
                    }
                }
            }
        }

        // Capa de la Barra Lateral de Canales
        ChannelSidebar {
            id: sidebar
            model: channelModel
            currentChannelIndex: ctrl.currentChannelIndex
            isFullScreen: ctrl.isFullScreen
            
            onChannelSelected: (realIndex) => {
                ctrl.playChannel(realIndex);
                // 👇 NUEVO: Tras hacer un clic con el ratón en la barra lateral,
                // devolvemos el foco al teclado de forma fulminante
                globalKeyboardHandler.forceActiveFocus();
            }
            
            onChannelHovered: (name) => {
                if (globalKeyboardHandler.activeFocus) return; // 🛠️ REPARADO: Filtro con el nuevo ID

                ctrl.osdHoveredChannelName = name;
                var epgData = channelModel.fetch_current_epg(name);
                if (epgData && epgData.title !== undefined) {
                    ctrl.epgTitle = epgData.title; 
                    ctrl.epgDescription = epgData.description;
                }
                if (ctrl.isFullScreen) epgDrawer.epgForceOpen = true;
            }
            
            onExited: {
                if (ctrl.isFullScreen) {
                    sidebar.sidebarForceOpen = false;
                    epgDrawer.epgForceOpen = false;
                }
                
                // 👇 🛠️ REPARADO: Forzamos el foco de vuelta al manejador de teclado real
                globalKeyboardHandler.forceActiveFocus();
            }
        }
    } 

    ChannelNumPopup {
        id: channelNumPopup
        onNumberAccepted: (numberStr) => ctrl.playChannelByNumber(numberStr)
    }

    Component.onCompleted: fileDialog.open()

    Timer {
        id: initScrollTimer
        interval: 100
        onTriggered: {
            var c = channelModel.rowCount();
            if (c > 0) { 
                var mid = 500000 - (500000 % c); 
                sidebar.positionListView(mid, ListView.Beginning); 
                mediaPlayer.audioOutput.volume = 1.0;
                ctrl.currentVolumePercent = 100;
                ctrl.playChannel(0); 
            }
        }
    }


    FileDialog {
        id: fileDialog
        title: "Carga tu lista Tvheadend"
        nameFilters: ["Archivos M3U (*.m3u *.m3u8)"]
        onAccepted: {
            var request = new XMLHttpRequest();
            request.open("GET", fileDialog.selectedFile, true);
            request.onreadystatechange = function() {
                if (request.readyState === XMLHttpRequest.DONE) {
                    channelModel.parse_m3u_content(request.responseText);
                    initScrollTimer.restart();
                }
            }
            request.send(null);
        }
    }
}
