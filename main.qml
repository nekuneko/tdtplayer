// main.qml
import QtQuick
import QtQuick.Controls
import QtMultimedia
import QtQuick.Dialogs
import QtCore // 🚀 AÑADIDO: Necesario para usar el componente Settings nativo
import "qml"

ApplicationWindow {
    id: window
    width: 1024; height: 768; visible: true
    title: "Tvheadend Native Player"

    // 🚀 AÑADIDO: Almacenamiento persistente de la ruta del archivo M3U
    Settings {
        id: appSettings
        property string lastM3uUrl: ""
    }

    PlaybackController {
        id: ctrl
        model: channelModel
        mediaPlayer: playerView.mediaPlayer
        sidebar: sidebar
        epgDrawer: epgDrawer
        onChannelZappedByKeyboard: { epgDrawer.epgForceOpen = true; keyboardEpgTimer.restart() }
    }

    KeyboardHandler {
        id: globalKeyboardHandler
        controller: ctrl; window: window; channelNumPopup: channelNumPopup; focus: true
    }

    FocusScope {
        id: mainFocusScope
        anchors.fill: parent

        VideoPlayerView {
            id: playerView
            window: window
            controller: ctrl
            sidebarItem: sidebar
            epgDrawerItem: epgDrawer
            configSidebarItem: configSidebar
            globalKeyboardHandlerItem: globalKeyboardHandler
            anchors.fill: parent 
        }

        EpgDrawer {
            id: epgDrawer
            channelName: ctrl.osdChannelName; channelNo: ctrl.osdChannelNo
            channelLogo: ctrl.osdChannelLogo 
            hoveredChannelName: ctrl.osdHoveredChannelName
            epgTitle: ctrl.epgTitle; epgDescription: ctrl.epgDescription; isFullScreen: ctrl.isFullScreen; sidebarItem: sidebar; z: 1 
            
            // 🚀 REPARADO: El ancho ahora se adapta y se acopla dinámicamente si la barra lateral está abierta
            width: sidebar.visible ? (parent.width - sidebar.width) : parent.width
            
            visible: !ctrl.isConfigMenuOpen && epgDrawer.epgForceOpen

            Timer { id: keyboardEpgTimer; interval: 3000; onTriggered: epgDrawer.epgForceOpen = false }
        }

        ChannelSidebar {
            id: sidebar
            model: channelModel; currentChannelIndex: ctrl.currentChannelIndex; isFullScreen: ctrl.isFullScreen; z: 1
            visible: !ctrl.isConfigMenuOpen && sidebar.sidebarForceOpen
            
            onChannelSelected: (realIndex) => { ctrl.playChannel(realIndex); globalKeyboardHandler.forceActiveFocus() }
            
            // 🚀 REPARADO: Vuelve a recibir el nombre (String) para que no tengas que cambiar tu archivo interno,
            // pero aplica un filtrado tolerante a fallos de texto y saltos de línea ocultos.
            onChannelHovered: (name) => {
                if (ctrl.zappingTimer.running) return
                if (!name) return
                
                // Limpiamos el texto recibido quitando espacios y retornos de carro invisibles (\r)
                var cleanHoverName = name.toString().trim().replace(/[\r\n]/g, "");
                ctrl.osdHoveredChannelName = cleanHoverName
                
                // Buscamos el logotipo en el modelo de forma ultra-tolerante
                var count = channelModel.rowCount()
                var foundLogo = ""
                for (var i = 0; i < count; i++) {
                    var idx = channelModel.index(i, 0)
                    var modelName = channelModel.data(idx, Qt.UserRole + 1)
                    if (modelName) {
                        var cleanModelName = modelName.toString().trim().replace(/[\r\n]/g, "");
                        if (cleanModelName === cleanHoverName) {
                            foundLogo = channelModel.data(idx, Qt.UserRole + 3) || ""
                            break
                        }
                    }
                }
                
                // Forzamos la actualización inmediata del logo en la interfaz gráfica
                ctrl.osdChannelLogo = foundLogo 

                var epgData = channelModel.fetch_current_epg(cleanHoverName)
                if (epgData && epgData.title !== undefined) { 
                    ctrl.epgTitle = epgData.title
                    ctrl.epgDescription = epgData.description 
                }
                epgDrawer.epgForceOpen = true
            }
            
            onExited: {
                sidebar.sidebarForceOpen = false
                epgDrawer.epgForceOpen = false
                sidebar.forceCenterScrollSync()
                ctrl.osdHoveredChannelName = ""
                
                // Al salir, restauramos el logotipo original del canal en reproducción real
                var currentIdx = channelModel.index(ctrl.currentChannelIndex, 0)
                ctrl.osdChannelLogo = channelModel.data(currentIdx, Qt.UserRole + 3) || ""
                
                var currentEpg = channelModel.fetch_current_epg(ctrl.osdChannelName)
                if (currentEpg && currentEpg.title !== undefined) { 
                    ctrl.epgTitle = currentEpg.title 
                    ctrl.epgDescription = currentEpg.description 
                }
                globalKeyboardHandler.forceActiveFocus()
            }
        }

        ConfigSidebar {
            id: configSidebar
            isFullScreen: ctrl.isFullScreen; z: 2
            onImportRequested: fileDialog.open()
            onMouseExitedSidebar: ctrl.restorePanelsAfterConfig()
            visible: configSidebar.sidebarForceOpen

        }
    } 

    ChannelNumPopup {
        id: channelNumPopup
        onNumberAccepted: (numberStr) => ctrl.playChannelByNumber(numberStr)
    }

    // 🚀 MODIFICADO: Carga automática de la lista persistente o apertura del diálogo si está vacío
    Component.onCompleted: {
        if (appSettings.lastM3uUrl !== "") {
            loadM3uFromUrl(appSettings.lastM3uUrl);
        } else {
            fileDialog.open();
        }
    }

    // 🚀 AÑADIDO: Función auxiliar para procesar la lista M3U mediante XMLHttpRequest
    function loadM3uFromUrl(url) {
        var request = new XMLHttpRequest()
        request.open("GET", url, true)
        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request.status === 200 || request.status === 0) { // 0 es válido para archivos locales file://
                    channelModel.parse_m3u_content(request.responseText)
                    initScrollTimer.restart()
                } else {
                    console.log("Error al cargar el archivo persistente, abriendo selector de archivos.")
                    fileDialog.open()
                }
            }
        }
        request.send(null)
    }

    Timer {
        id: initScrollTimer
        interval: 100
        onTriggered: {
            var c = channelModel.rowCount()
            if (c > 0) { 
                sidebar.positionListView(500000 - (500000 % c), ListView.Beginning) 
                playerView.mediaPlayer.audioOutput.volume = 1.0; ctrl.currentVolumePercent = 100; ctrl.playChannel(0) 
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Carga tu lista Tvheadend"
        nameFilters: ["Archivos M3U (*.m3u *.m3u8)"]
        onAccepted: {
            var selected = fileDialog.selectedFile.toString()
            appSettings.lastM3uUrl = selected // 🚀 AÑADIDO: Guarda la ruta para la próxima sesión
            loadM3uFromUrl(selected)
        }
    }
}
