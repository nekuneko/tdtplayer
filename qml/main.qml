// qml/main.qml
import QtQuick
import QtQuick.Controls
import QtCore

ApplicationWindow {
    id: window
    width: 1024
    height: 768
    visible: true
    title: "Tvheadend Native Player"
    color: appTheme.bgCanvas

    Theme {
        id: appTheme
        currentTheme: appSettings.lastTheme
    }

    readonly property var epgGridOverlayItem: epgGridOverlayLoader.item
    property alias epgGridOverlayLoaderItemActive: epgGridOverlayLoader.active
    property bool isBooting: true
    property bool isHdrStream: false
    property var localLogoCache: ({})
    property var globalChannelModel: channelModel

    x: appSettings.windowX !== -1 ? appSettings.windowX : (Screen.width - width) / 2
    y: appSettings.windowY !== -1 ? appSettings.windowY : (Screen.height - height) / 2
    visibility: appSettings.lastIsFullScreen ? Window.FullScreen : Window.Windowed

    Settings {
        id: appSettings
        property string lastM3uUrl: ""
        property int lastChannelIndex: 0
        property int windowX: -1
        property int windowY: -1
        property int windowWidth: 1024
        property int windowHeight: 768
        property bool lastIsFullScreen: false
        property string lastTheme: "CINEMATIC_COLOR"
    }

    PlaybackController {
        id: ctrl
        model: channelModel
        mediaPlayer: playerView.mediaPlayer
        sidebar: sidebar
        epgDrawer: epgDrawer
        onChannelZappedByKeyboard: epgDrawer.epgForceOpen = true
    }

    PipWindowController {
        id: windowController
        window: window
        appSettings: appSettings
        ctrl: ctrl
    }

    EpgBootstrapper {
        id: epgBootstrapper
        window: window
        playerView: playerView
        epgDrawer: epgDrawer
        ctrl: ctrl
    }

    KeyboardHandler {
        id: globalKeyboardHandler
        controller: ctrl
        window: window
        windowController: windowController
        channelNumPopup: channelNumPopup
        focus: true
    }

    SidebarHoverSync {
        id: sidebarHoverSync
        sidebar: sidebar
        epgDrawer: epgDrawer
        ctrl: ctrl
        model: channelModel
        window: window
        keyboardHandler: globalKeyboardHandler
    }

    FocusScope {
        id: mainFocusScope
        anchors.fill: parent

        VideoPlayerView {
            id: playerView
            window: window
            windowController: windowController
            controller: ctrl
            sidebarItem: sidebar
            epgDrawerItem: epgDrawer
            configSidebarItem: configSidebar
            globalKeyboardHandlerItem: globalKeyboardHandler
            anchors.fill: parent
        }

        EpgDrawer {
            id: epgDrawer
            channelName: ctrl.osdChannelName
            channelNo: ctrl.osdChannelNo
            channelLogo: ctrl.osdChannelLogo
            hoveredChannelName: ctrl.osdHoveredChannelName
            epgTitle: ctrl.epgTitle
            epgDescription: ctrl.epgDescription
            sidebarItem: sidebar
            z: 1
            width: sidebar.visible ? (parent.width - sidebar.width - appTheme.px(12)) : (parent.width - appTheme.px(24))
            visible: !ctrl.isConfigMenuOpen && epgDrawer.epgForceOpen
        }

        Connections {
            target: epgDrawer
            function onEpgForceOpenChanged() {
                if (epgDrawer.epgForceOpen && typeof playerView !== "undefined") {
                    playerView.resetMouseCursor();
                    epgBootstrapper.resetTimer();
                }
            }
        }

        ChannelSidebar {
            id: sidebar
            model: channelModel
            currentChannelIndex: ctrl.currentChannelIndex
            z: 1
            visible: !ctrl.isConfigMenuOpen && sidebar.sidebarForceOpen
            appThemeItem: appTheme

            onChannelSelected: realIndex => {
                ctrl.playChannel(realIndex, true);
                globalKeyboardHandler.forceActiveFocus();
            }
            onChannelHovered: name => sidebarHoverSync.handleHover(name)
            onExited: sidebarHoverSync.handleExit()
        }

        ConfigSidebar {
            id: configSidebar
            z: 2
            visible: configSidebar.sidebarForceOpen
            appSettingsItem: appSettings
            appThemeItem: appTheme

            onImportRequested: dataLoader.fileSelectorOpenRequested()
            onMouseExitedSidebar: ctrl.restorePanelsAfterConfig()
        }

        ScreenshotToast {
            z: 20
        }
    }

    Loader {
        id: epgGridOverlayLoader
        anchors.fill: parent
        z: 10
        asynchronous: true

        Component.onCompleted: {
            epgGridOverlayLoader.setSource("EpgGridOverlay.qml", {
                "channelModel": channelModel,
                "appThemeItem": appTheme,
                "currentChannelIndex": Qt.binding(function () {
                    return ctrl.currentChannelIndex;
                })
            });
        }

        onLoaded: item.visible = false
    }

    Connections {
        target: epgGridOverlayLoader.item
        ignoreUnknownSignals: true

        function onChannelSelected(realIndex) {
            epgGridOverlayLoader.item.visible = false;
            ctrl.playChannel(realIndex, true);
            globalKeyboardHandler.forceActiveFocus();
        }

        function onCloseRequested() {
            epgGridOverlayLoader.item.visible = false;
            globalKeyboardHandler.forceActiveFocus();
        }
    }

    ChannelNumPopup {
        id: channelNumPopup
        onNumberAccepted: numberStr => ctrl.playChannelByNumber(numberStr)
    }

    Connections {
        target: channelModel
        function onLogoCacheChanged() {
            window.localLogoCache = channelModel.logoCache;
        }
    }

    EpgDataLoader {
        id: dataLoader
        window: window
        appSettings: appSettings
        playerView: playerView
        ctrl: ctrl
        sidebar: sidebar
    }
}
