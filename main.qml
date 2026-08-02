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

            // 👇 NUEVO: Temporizador para ocultar el cursor tras 0.5 segundos de inactividad
            Timer {
                id: mouseInactivityTimer
                interval: 500 // Tiempo en milisegundos (0.5 segundos)
                running: true 
                repeat: false
                onTriggered: {
                    // Esconde el puntero del ratón cambiando la forma del cursor a "None"
                    videoMouseTracker.cursorShape = Qt.BlankCursor
                }
            }

            // 👇 NUEVO: Área interactiva transparente para capturar el movimiento del ratón
            MouseArea {
                id: videoMouseTracker
                anchors.fill: parent
                hoverEnabled: true
                
                // Mantiene el orden de capas para no pisar los clics de los botones OSD o el doble tap
                z: -1 

                // Cada vez que la coordenada X o Y del ratón cambia (el usuario mueve el ratón)
                onPositionChanged: {
                    // 1. Restauramos el puntero normal de inmediato
                    videoMouseTracker.cursorShape = Qt.ArrowCursor
                    
                    // 2. Reiniciamos la cuenta atrás de los 2.5 segundos
                    mouseInactivityTimer.restart()
                }
            }
            
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
                    
                    // 🛠️ REPARADO: Al entrar el ratón, encendemos la propiedad del componente directamente
                    onEntered: { 
                        if (ctrl.isFullScreen) {
                            epgDrawer.epgForceOpen = true 
                        }
                    }
                }

                // 👇 NUEVO: Zona interactiva invisible en el borde izquierdo (Hover en pantalla completa)
                MouseArea {
                    id: leftEdgeSwipeArea
                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                    width: 50 // Banda interactiva de 50 píxeles a la izquierda de la pantalla
                    hoverEnabled: true
                    
                    // Al entrar el ratón a la izquierda, congelamos los otros menús y abrimos configuración
                    onEntered: { 
                        ctrl.openConfigAndCollapseOthers();
                        configSidebar.sidebarForceOpen = true;
                    }
                }
                
                MouseArea {
                    id: rightEdgeSwipeArea
                    anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                    width: ctrl.isFullScreen ? 50 : 0 
                    hoverEnabled: true
                    onEntered: { if (ctrl.isFullScreen) sidebar.sidebarForceOpen = true }
                }

                // ===================================================================
                // CAPA INVISIBLE 1: Cierra la barra de canales (Derecha) al hacer clic fuera
                // ===================================================================
                MouseArea {
                    anchors.fill: parent
                    
                    // Deja libre el espacio ocupado por la barra derecha para poder hacer clics en los canales
                    anchors.rightMargin: sidebar.width 
                    
                    // Solo actúa si estamos en pantalla completa y el menú derecho está desplegado
                    visible: ctrl.isFullScreen && sidebar.sidebarForceOpen
                    
                    onClicked: sidebar.sidebarForceOpen = false
                }

                // ===================================================================
                // CAPA INVISIBLE 2: Cierra el menú de configuración (Izquierda) al hacer clic fuera
                // ===================================================================
                MouseArea {
                    anchors.fill: parent
                    
                    // Deja libre el espacio ocupado por la barra izquierda para poder pulsar sus opciones
                    anchors.leftMargin: configSidebar.width 
                    
                    // Actúa SIEMPRE (en ventana o full screen) si el menú izquierdo está desplegado
                    visible: configSidebar.visible
                    
                    onClicked: {
                        configSidebar.sidebarForceOpen = false;
                        ctrl.restorePanelsAfterConfig(); // Restaura las barras que se habían cerrado
                    }
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

                // 🛠️ REPARADO: Desplazamiento por margen absoluto con interpolación fluida
                ClockWidget {
                    id: clockWidget
                    anchors.top: parent.top
                    anchors.right: parent.right // Mantenemos el anclaje fijo y estable
                    
                    // Separación vertical estándar según el formato de pantalla
                    anchors.topMargin: ctrl.isFullScreen ? 40 : 20
                    
                    // 🛠️ REPARADO: Si la barra lateral está visible en pantalla completa,
                    // sumamos su ancho real (290px) al margen base (40px) para empujar el reloj a la izquierda.
                    // Si estamos en ventana, el margen es de 20px fijos porque el contenedor ya está encogido.
                    anchors.rightMargin: (sidebar.visible && ctrl.isFullScreen && sidebar.width > 0)
                                   ? (sidebar.width + 40)
                                   : (ctrl.isFullScreen ? 40 : 20)
                    
                    opacity: ctrl.clockOpacity 
                    
                    // 🛠️ REPARADO: Aplicamos una animación numérica sobre el margen. 
                    // Al abrir la barra lateral con el ratón, el reloj viajará suavemente a la izquierda.
                    Behavior on anchors.rightMargin {
                        NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
                    }
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
            
            // Filtro de bloqueo de conmutación exclusivo universal
            visible: !ctrl.isConfigMenuOpen && (!ctrl.isFullScreen || epgDrawer.epgForceOpen)

            Timer {
                id: keyboardEpgTimer
                interval: 3000 
                onTriggered: epgDrawer.epgForceOpen = false
            }

            Connections {
                target: ctrl
                function onChannelZappedByKeyboard() {
                    if (ctrl.isFullScreen) {
                        epgDrawer.epgForceOpen = true; 
                        keyboardEpgTimer.restart();     
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
            visible: !ctrl.isConfigMenuOpen && (!ctrl.isFullScreen || sidebar.sidebarForceOpen)

            
            onChannelSelected: (realIndex) => {
                ctrl.playChannel(realIndex);
                globalKeyboardHandler.forceActiveFocus();
            }
            
            // 🛠️ REPARADO: Filtro corregido. Si el usuario está manteniendo presionadas 
            // las flechas, el zappingTimer estará activo en QML; si está quieto, el ratón recupera prioridad.
            onChannelHovered: (name) => {
                if (ctrl.zappingTimer.running) return; // Evita interferencias mientras se pulsa rápido

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

                    // 🛠️ REPARADO: El recentrado automático de la lista al medio 
                    // de la pantalla SÓLO se ejecuta si estamos en pantalla completa.
                    sidebar.forceCenterScrollSync();
                }
                
                // Limpiamos los textos flotantes para que la guía recupere el canal reproduciéndose
                ctrl.osdHoveredChannelName = "";
                var currentEpg = channelModel.fetch_current_epg(ctrl.osdChannelName);
                if (currentEpg && currentEpg.title !== undefined) {
                    ctrl.epgTitle = currentEpg.title;
                    ctrl.epgDescription = currentEpg.description;
                }

                globalKeyboardHandler.forceActiveFocus();
            }
        }

        // Componente del nuevo menú de configuración izquierdo (Declarado antes del vídeo para capas)
        ConfigSidebar {
            id: configSidebar
            isFullScreen: ctrl.isFullScreen
            onImportRequested: fileDialog.open() // El botón ahora activa la carga
        
            onMouseExitedSidebar: {
                ctrl.restorePanelsAfterConfig();
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
