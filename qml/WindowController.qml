// qml/WindowController.qml
import QtQuick
import QtCore

Item {
    id: root

    required property var window
    required property var appSettings
    required property var ctrl

    property bool isPipMode: false
    property int savedX: 100
    property int savedY: 100
    property int savedWidth: 1024
    property int savedHeight: 768
    property bool savedFullScreen: false
    property int defaultFlags: 0

    Component.onCompleted: {
        defaultFlags = root.window.flags;
    }

    function togglePipMode() {
        if (!isPipMode) {
            // 1. Guardamos el estado actual antes de entrar en PiP
            savedFullScreen = (root.window.visibility === Window.FullScreen);
            if (savedFullScreen) {
                root.window.visibility = Window.Windowed;
                root.ctrl.isFullScreen = false;
            }
            savedX = root.window.x;
            savedY = root.window.y;
            savedWidth = root.window.width;
            savedHeight = root.window.height;

            // 2. Cerramos paneles laterales/EPG si estuvieran abiertos
            if (root.ctrl.sidebar)
                root.ctrl.sidebar.sidebarForceOpen = false;
            if (root.ctrl.epgDrawer)
                root.ctrl.epgDrawer.epgForceOpen = false;

            isPipMode = true;

            // 3. Activamos ventana flotante sin bordes y siempre encima (Windows + Linux X11)
            root.window.flags = defaultFlags | Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint;

            // 4. Tamaño compacto 16:9 en la esquina inferior derecha
            var pipW = 420;
            var pipH = 236;
            root.window.width = pipW;
            root.window.height = pipH;
            root.window.x = Math.max(0, Screen.desktopAvailableWidth - pipW - 24);
            root.window.y = Math.max(0, Screen.desktopAvailableHeight - pipH - 24);
        } else {
            // Restauramos ventana normal
            isPipMode = false;
            root.window.flags = defaultFlags;
            root.window.x = savedX;
            root.window.y = savedY;
            root.window.width = savedWidth;
            root.window.height = savedHeight;

            if (savedFullScreen) {
                root.window.visibility = Window.FullScreen;
                root.ctrl.isFullScreen = true;
            }
        }
    }

    // Enlaces de sincronización bidireccionales nativos con el motor de persistencia Settings
    Connections {
        target: root.window
        function onXChanged() {
            if (!root.isPipMode && root.window.visibility === Window.Windowed && !root.window.isBooting) {
                root.appSettings.windowX = root.window.x;
            }
        }

        function onYChanged() {
            if (!root.isPipMode && root.window.visibility === Window.Windowed && !root.window.isBooting) {
                root.appSettings.windowY = root.window.y;
            }
        }

        function onWidthChanged() {
            if (!root.isPipMode && root.window.visibility === Window.Windowed && !root.window.isBooting) {
                root.appSettings.windowWidth = root.window.width;
            }
        }

        function onHeightChanged() {
            if (!root.isPipMode && root.window.visibility === Window.Windowed && !root.window.isBooting) {
                root.appSettings.windowHeight = root.window.height;
            }
        }

        function onVisibilityChanged() {
            if (root.window.isBooting || root.isPipMode)
                return;

            if (root.window.visibility === Window.FullScreen) {
                root.appSettings.lastIsFullScreen = true;
                root.ctrl.isFullScreen = true;
            } else if (root.window.visibility === Window.Windowed) {
                root.appSettings.lastIsFullScreen = false;
                root.ctrl.isFullScreen = false;
            }
        }
    }
}
