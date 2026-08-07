// main.qml
import QtQuick
import QtQuick.Controls
import QtMultimedia
import QtCore 
import "qml"

ApplicationWindow {
    id: window
    width: 1024; height: 768; visible: true
    title: "Tvheadend Native Player"

    // Orquestador de estilos raíz sincronizado con la persistencia en disco
    Theme {
        id: appTheme
        currentTheme: appSettings.lastTheme
    }

    readonly property var epgGridOverlayItem: epgGridOverlayLoader.item
    property alias epgGridOverlayLoaderItemActive: epgGridOverlayLoader.active
    property bool isBooting: true
    property var localLogoCache: ({})

    x: appSettings.windowX !== -1 ? appSettings.windowX : (Screen.width - width) / 2
    y: appSettings.windowY !== -1 ? appSettings.windowY : (Screen.height - height) / 2
    visibility: appSettings.lastIsFullScreen ? Window.FullScreen : Window.Windowed

    onXChanged: if (window.visibility === Window.Windowed && !window.isBooting) appSettings.windowX = window.x
    onYChanged: if (window.visibility === Window.Windowed && !window.isBooting) appSettings.windowY = window.y
    onWidthChanged: if (window.visibility === Window.Windowed && !window.isBooting) appSettings.windowWidth = window.width
    onHeightChanged: if (window.visibility === Window.Windowed && !window.isBooting) appSettings.windowHeight = window.height

    onVisibilityChanged: {
        if (window.isBooting) return
        if (window.visibility === Window.FullScreen) { appSettings.lastIsFullScreen = true; ctrl.isFullScreen = true }
        else if (window.visibility === Window.Windowed) { appSettings.lastIsFullScreen = false; ctrl.isFullScreen = false }
    }

    Settings {
        id: appSettings
        property string lastM3uUrl: ""; property int lastChannelIndex: 0 
        property int windowX: -1; property int windowY: -1; property int windowWidth: 1024; property int windowHeight: 768
        property bool lastIsFullScreen: false
        // 🚀 PERSISTENCIA DE TEMA: Almacena la cadena identificadora del perfil visual
        property string lastTheme: "CINEMATIC_COLOR"
    }

    PlaybackController {
        id: ctrl; model: channelModel; mediaPlayer: playerView.mediaPlayer; sidebar: sidebar; epgDrawer: epgDrawer
        onChannelZappedByKeyboard: { epgDrawer.epgForceOpen = true; keyboardEpgTimer.restart() }
    }

    KeyboardHandler {
        id: globalKeyboardHandler; controller: ctrl; window: window; channelNumPopup: channelNumPopup; focus: true
    }

    FocusScope {
        id: mainFocusScope
        anchors.fill: parent

        VideoPlayerView {
            id: playerView; window: window; controller: ctrl; sidebarItem: sidebar
            epgDrawerItem: epgDrawer; configSidebarItem: configSidebar; globalKeyboardHandlerItem: globalKeyboardHandler; anchors.fill: parent 
        }

        EpgDrawer {
            id: epgDrawer; channelName: ctrl.osdChannelName; channelNo: ctrl.osdChannelNo; channelLogo: ctrl.osdChannelLogo 
            hoveredChannelName: ctrl.osdHoveredChannelName; epgTitle: ctrl.epgTitle; epgDescription: ctrl.epgDescription
            isFullScreen: ctrl.isFullScreen; sidebarItem: sidebar; z: 1 
            width: sidebar.visible ? (parent.width - sidebar.width) : parent.width
            visible: !ctrl.isConfigMenuOpen && epgDrawer.epgForceOpen
            Timer { id: keyboardEpgTimer; interval: 3000; onTriggered: epgDrawer.epgForceOpen = false }
        }

        Connections {
            target: epgDrawer
            function onEpgForceOpenChanged() { if (epgDrawer.epgForceOpen && typeof playerView !== "undefined") playerView.resetMouseCursor() }
        }

        ChannelSidebar {
            id: sidebar; model: channelModel; currentChannelIndex: ctrl.currentChannelIndex; isFullScreen: ctrl.isFullScreen; z: 1
            visible: !ctrl.isConfigMenuOpen && sidebar.sidebarForceOpen
            onChannelSelected: (realIndex) => { ctrl.playChannel(realIndex); globalKeyboardHandler.forceActiveFocus() }
            
            onChannelHovered: (name) => {
                if (ctrl.zappingTimer.running || !name) return
                var cleanHoverName = name.toString().trim().replace(/[\r\n]/g, "")
                ctrl.osdHoveredChannelName = cleanHoverName
                var count = channelModel.rowCount(), foundLogo = "", foundChNo = ""
                for (var i = 0; i < count; i++) {
                    var idx = channelModel.index(i, 0), modelName = channelModel.data(idx, Qt.UserRole + 1)
                    if (modelName && modelName.toString().trim().replace(/[\r\n]/g, "") === cleanHoverName) {
                        foundLogo = window.localLogoCache[cleanHoverName] || ""
                        foundChNo = channelModel.data(idx, Qt.UserRole + 4) || i.toString(); break
                    }
                }
                ctrl.osdChannelNo = foundChNo; ctrl.osdChannelLogo = foundLogo 
                var epgData = channelModel.fetch_current_epg(cleanHoverName)
                if (epgData && epgData.title !== undefined) { ctrl.epgTitle = epgData.title; ctrl.epgDescription = epgData.description }
                epgDrawer.epgForceOpen = true
            }
            
            onExited: {
                sidebar.sidebarForceOpen = false; epgDrawer.epgForceOpen = false; sidebar.forceCenterScrollSync(); ctrl.osdHoveredChannelName = ""
                var currentIdx = channelModel.index(ctrl.currentChannelIndex, 0), currentName = channelModel.data(currentIdx, Qt.UserRole + 1) || ""
                if (currentName !== "") {
                    var cleanCurrentName = currentName.toString().trim().replace(/[\r\n]/g, "")
                    ctrl.osdChannelLogo = window.localLogoCache[cleanCurrentName] || ""
                    ctrl.osdChannelNo = channelModel.data(currentIdx, Qt.UserRole + 4) || ctrl.currentChannelIndex.toString()
                }
                var currentEpg = channelModel.fetch_current_epg(ctrl.osdChannelName)
                if (currentEpg && currentEpg.title !== undefined) { ctrl.epgTitle = ctrl.epgTitle; ctrl.epgDescription = currentEpg.description }
                globalKeyboardHandler.forceActiveFocus()
            }
        }

        ConfigSidebar {
            id: configSidebar; isFullScreen: ctrl.isFullScreen; z: 2; onImportRequested: dataLoader.loadM3uFromUrl("")
            onMouseExitedSidebar: ctrl.restorePanelsAfterConfig(); visible: configSidebar.sidebarForceOpen
            
            // 🚀 ENLACE DE PROPIEDADES: Pasamos el control al panel lateral
            appSettingsItem: appSettings
            appThemeItem: appTheme
        }
    } 

    Loader {
        id: epgGridOverlayLoader; anchors.fill: parent; z: 10; active: false; enabled: active; source: "qml/EpgGridOverlay.qml"
        onLoaded: {
            item.channelModel = channelModel; item.currentChannelIndex = ctrl.currentChannelIndex
            item.channelSelected.connect(function(realIndex) { epgGridOverlayLoader.active = false; ctrl.playChannel(realIndex); globalKeyboardHandler.forceActiveFocus() })
            item.closeRequested.connect(function() { epgGridOverlayLoader.active = false; globalKeyboardHandler.forceActiveFocus() })
            item.visible = true
        }
    }

    ChannelNumPopup { id: channelNumPopup; onNumberAccepted: (numberStr) => ctrl.playChannelByNumber(numberStr) }
    Connections { target: channelModel; function onLogoCacheChanged() { window.localLogoCache = channelModel.logoCache } }

    Component.onCompleted: { ctrl.isFullScreen = appSettings.lastIsFullScreen; window.isBooting = false }

    EpgDataLoader {
        id: dataLoader
        window: window; appSettings: appSettings
        playerView: playerView; ctrl: ctrl; sidebar: sidebar
    }
}
