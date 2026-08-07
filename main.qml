// main.qml
import QtQuick
import QtQuick.Controls
import QtMultimedia
import QtQuick.Dialogs
import QtCore 
import "qml"

ApplicationWindow {
    id: window
    visible: true
    title: "Tvheadend Native Player"

    // Propiedad interna intermedia para evitar bucles de actualización infinita durante el arranque
    property bool isBooting: true

    // Persistencia geométrica multimonitor reactiva
    x: appSettings.windowX !== -1 ? appSettings.windowX : (Screen.width - width) / 2
    y: appSettings.windowY !== -1 ? appSettings.windowY : (Screen.height - height) / 2
    width: appSettings.windowWidth > 0 ? appSettings.windowWidth : 1024
    height: appSettings.windowHeight > 0 ? appSettings.windowHeight : 768

    // 🚀 RESTAURACIÓN NATIVA EN ARRANQUE: Enlazamos el estado inicial de forma declarativa directa
    visibility: appSettings.lastIsFullScreen ? Window.FullScreen : Window.Windowed

    onXChanged: if (window.visibility === Window.Windowed && !window.isBooting) appSettings.windowX = window.x
    onYChanged: if (window.visibility === Window.Windowed && !window.isBooting) appSettings.windowY = window.y
    onWidthChanged: if (window.visibility === Window.Windowed && !window.isBooting) appSettings.windowWidth = window.width
    onHeightChanged: if (window.visibility === Window.Windowed && !window.isBooting) appSettings.windowHeight = window.height

    // Escuchamos el cambio de estado para guardar en caliente de forma bidireccional segura
    onVisibilityChanged: {
        if (window.isBooting) return // Blindaje: no guardamos nada mientras la app se está construyendo
        
        if (window.visibility === Window.FullScreen) {
            appSettings.lastIsFullScreen = true
            ctrl.isFullScreen = true
        } else if (window.visibility === Window.Windowed) {
            appSettings.lastIsFullScreen = false
            ctrl.isFullScreen = false
        }
    }

    Settings {
        id: appSettings
        property string lastM3uUrl: ""
        property int lastChannelIndex: 0 
        property int windowX: -1
        property int windowY: -1
        property int windowWidth: 1024
        property int windowHeight: 768
        property bool lastIsFullScreen: false
    }

    property var localLogoCache: ({})

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
            
            width: sidebar.visible ? (parent.width - sidebar.width) : parent.width
            visible: !ctrl.isConfigMenuOpen && epgDrawer.epgForceOpen

            Timer { id: keyboardEpgTimer; interval: 3000; onTriggered: epgDrawer.epgForceOpen = false }
        }

        Connections {
            target: epgDrawer
            function onEpgForceOpenChanged() {
                if (epgDrawer.epgForceOpen) {
                    if (typeof playerView !== "undefined") {
                        playerView.resetMouseCursor()
                    }
                }
            }
        }

        ChannelSidebar {
            id: sidebar
            model: channelModel; currentChannelIndex: ctrl.currentChannelIndex; isFullScreen: ctrl.isFullScreen; z: 1
            visible: !ctrl.isConfigMenuOpen && sidebar.sidebarForceOpen
            
            onChannelSelected: (realIndex) => { ctrl.playChannel(realIndex); globalKeyboardHandler.forceActiveFocus() }
            
            onChannelHovered: (name) => {
                if (ctrl.zappingTimer.running) return
                if (!name) return
                
                var cleanHoverName = name.toString().trim().replace(/[\r\n]/g, "");
                ctrl.osdHoveredChannelName = cleanHoverName
                
                var count = channelModel.rowCount()
                var foundLogo = ""
                var foundChNo = ""
                
                for (var i = 0; i < count; i++) {
                    var idx = channelModel.index(i, 0)
                    var modelName = channelModel.data(idx, Qt.UserRole + 1)
                    if (modelName) {
                        var cleanModelName = modelName.toString().trim().replace(/[\r\n]/g, "");
                        if (cleanModelName === cleanHoverName) {
                            foundLogo = window.localLogoCache[cleanModelName] || ""
                            foundChNo = channelModel.data(idx, Qt.UserRole + 4) || i.toString()
                            break
                        }
                    }
                }
                
                ctrl.osdChannelNo = foundChNo
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
                
                var currentIdx = channelModel.index(ctrl.currentChannelIndex, 0)
                var currentName = channelModel.data(currentIdx, Qt.UserRole + 1) || ""
                if (currentName !== "") {
                    var cleanCurrentName = currentName.toString().trim().replace(/[\r\n]/g, "");
                    ctrl.osdChannelLogo = window.localLogoCache[cleanCurrentName] || ""
                    ctrl.osdChannelNo = channelModel.data(currentIdx, Qt.UserRole + 4) || ctrl.currentChannelIndex.toString()
                }
                
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

    Connections {
        target: channelModel
        function onLogoCacheChanged() {
            window.localLogoCache = channelModel.logoCache
        }
    }

    Component.onCompleted: {
        // Inicializamos los flags del controlador para que los componentes hijos escalen bien desde el frame 1
        ctrl.isFullScreen = appSettings.lastIsFullScreen
        
        // Abrimos el candado de escritura: a partir de ahora cualquier cambio de tamaño se guardará en disco
        window.isBooting = false

        if (appSettings.lastM3uUrl !== "") {
            loadM3uFromUrl(appSettings.lastM3uUrl);
        } else {
            fileDialog.open();
        }
    }

    function loadM3uFromUrl(url) {
        var request = new XMLHttpRequest()
        request.open("GET", url, true)
        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request.status === 200 || request.status === 0) { 
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
                var savedIndex = appSettings.lastChannelIndex
                if (savedIndex < 0 || savedIndex >= c) {
                    savedIndex = 0
                }
                
                sidebar.positionListView(500000 - (500000 % c) + savedIndex, ListView.Beginning) 
                
                playerView.mediaPlayer.audioOutput.volume = 1.0
                ctrl.currentVolumePercent = 100
                
                ctrl.playChannel(savedIndex) 
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Carga tu lista Tvheadend"
        nameFilters: ["Archivos M3U (*.m3u *.m3u8)"]
        onAccepted: {
            var selected = fileDialog.selectedFile.toString()
            appSettings.lastM3uUrl = selected 
            loadM3uFromUrl(selected)
        }
    }
}
