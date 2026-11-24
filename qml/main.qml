// main.qml
import QtQuick
import QtQuick.Controls
import QtCore

ApplicationWindow {
    id: window
    width: 1024
    height: 768
    visible: true
    title: "Tvheadend Native Player"

    Theme {
        id: appTheme
        currentTheme: appSettings.lastTheme
    }

    readonly property var epgGridOverlayItem: epgGridOverlayLoader.item
    property alias epgGridOverlayLoaderItemActive: epgGridOverlayLoader.active
    property bool isBooting: true
    property var localLogoCache: ({})
    property var globalChannelModel: channelModel

    // Configuración elástica de arranque de coordenadas
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
        onChannelZappedByKeyboard: {
            epgDrawer.epgForceOpen = true;
        }
    }

    // 🚀 INTEGRACIÓN MODULAR: Controladores de ventana y de arranque de flujos
    WindowController {
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
            isFullScreen: ctrl.isFullScreen
            sidebarItem: sidebar
            z: 1
            width: sidebar.visible ? (parent.width - sidebar.width) : parent.width
            visible: !ctrl.isConfigMenuOpen && epgDrawer.epgForceOpen
        }

        Connections {
            target: epgDrawer
            function onEpgForceOpenChanged() {
                if (epgDrawer.epgForceOpen && typeof playerView !== "undefined") {
                    playerView.resetMouseCursor();
                    // Fuerza la reevaluación estática y detiene el reloj si la barra está abierta
                    epgBootstrapper.resetTimer();
                }
            }
        }

        ChannelSidebar {
            id: sidebar
            model: channelModel
            currentChannelIndex: ctrl.currentChannelIndex
            isFullScreen: ctrl.isFullScreen
            z: 1
            visible: !ctrl.isConfigMenuOpen && sidebar.sidebarForceOpen
            appThemeItem: appTheme

            onChannelSelected: realIndex => {
                ctrl.playChannel(realIndex);
                globalKeyboardHandler.forceActiveFocus();
            }

            // 🚀 SISTEMA DE AMORTIGUACIÓN (DEBOUNCE): Almacenamiento intermedio de memoria
            property string pendingHoverName: ""

            Timer {
                id: debounceHoverTimer
                interval: 150 // Milisegundos de espera para confirmar que el usuario quiere ver el EPG
                repeat: false
                onTriggered: {
                    if (sidebar.pendingHoverName === "")
                        return;
                    ctrl.osdHoveredChannelName = sidebar.pendingHoverName;
                    var count = channelModel.rowCount(), foundLogo = "", foundChNo = "";

                    // Ejecución bajo demanda: El bucle pesado solo corre si el ratón se queda quieto
                    for (var i = 0; i < count; i++) {
                        var idx = channelModel.index(i, 0);
                        var modelName = channelModel.data(idx, Qt.UserRole + 1);
                        if (modelName && modelName.toString().trim().replace(/[\r\n]/g, "") === sidebar.pendingHoverName) {
                            foundLogo = window.localLogoCache[sidebar.pendingHoverName] || "";
                            foundChNo = channelModel.data(idx, Qt.UserRole + 4) || i.toString();
                            break;
                        }
                    }

                    ctrl.osdChannelNo = foundChNo;
                    ctrl.osdChannelLogo = foundLogo;

                    var epgData = channelModel.fetch_current_epg(sidebar.pendingHoverName);
                    if (epgData && epgData.title !== undefined) {
                        ctrl.epgTitle = epgData.title;
                        ctrl.epgDescription = epgData.description;
                    }
                    epgDrawer.epgForceOpen = true;
                }
            }

            // 🚀 MANEJADOR ULTRA LIGERO: Al deslizar el ratón rápido, solo guardamos el nombre y posponemos la carga pesada
            onChannelHovered: name => {
                if (ctrl.zappingTimer.running || !name)
                    return;
                var cleanHoverName = name.toString().trim().replace(/[\r\n]/g, "");

                // Si el ratón está en movimiento constante, reiniciamos el temporizador sin saturar la CPU
                sidebar.pendingHoverName = cleanHoverName;
                debounceHoverTimer.restart();
            }

            onExited: {
                // En Windows, Qt dispara onExited en el MouseArea padre cuando un ItemDelegate hijo captura el hover
                if (sidebar.containsMouse)
                    return;
                    
                // Cancelamos cualquier petición pendiente de inmediato al sacar el ratón de la barra
                debounceHoverTimer.stop();
                sidebar.pendingHoverName = "";

                sidebar.sidebarForceOpen = false;
                epgDrawer.epgForceOpen = false;
                sidebar.forceCenterScrollSync();
                ctrl.osdHoveredChannelName = "";

                var currentIdx = channelModel.index(ctrl.currentChannelIndex, 0);
                var currentName = channelModel.data(currentIdx, Qt.UserRole + 1) || "";
                if (currentName !== "") {
                    var cleanCurrentName = currentName.toString().trim().replace(/[\r\n]/g, "");
                    ctrl.osdChannelLogo = window.localLogoCache[cleanCurrentName] || "";
                    ctrl.osdChannelNo = channelModel.data(currentIdx, Qt.UserRole + 4) || ctrl.currentChannelIndex.toString();
                }
                var currentEpg = channelModel.fetch_current_epg(ctrl.osdChannelName);
                if (currentEpg && currentEpg.title !== undefined) {
                    ctrl.epgTitle = currentEpg.title;
                    ctrl.epgDescription = currentEpg.description;
                }
                globalKeyboardHandler.forceActiveFocus();
            }
        }

        ConfigSidebar {
            id: configSidebar
            isFullScreen: ctrl.isFullScreen
            z: 2
            visible: configSidebar.sidebarForceOpen
            appSettingsItem: appSettings
            appThemeItem: appTheme

            // 🚀 DISPARO DE SEÑAL: Emitimos la señal hacia el cargador de datos
            onImportRequested: dataLoader.fileSelectorOpenRequested()

            onMouseExitedSidebar: ctrl.restorePanelsAfterConfig()
        }
    }

    Loader {
        id: epgGridOverlayLoader
        anchors.fill: parent
        z: 10
        asynchronous: true

        // 🚀 INYECCIÓN MAESTRA EN TIEMPO DE COMPILACIÓN: Pasamos las variables obligatorias al instanciar el archivo
        Component.onCompleted: {
            epgGridOverlayLoader.setSource("EpgGridOverlay.qml", {
                "channelModel": channelModel,
                "appThemeItem": appTheme,
                "currentChannelIndex": Qt.binding(function () {
                    return ctrl.currentChannelIndex;
                })
            });
        }

        onLoaded: {
            item.visible = false;
        }
    }

    Connections {
        target: epgGridOverlayLoader.item
        ignoreUnknownSignals: true

        function onChannelSelected(realIndex) {
            epgGridOverlayLoader.item.visible = false;
            ctrl.playChannel(realIndex);
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

    Component.onCompleted: {
        ctrl.isFullScreen = appSettings.lastIsFullScreen;
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
