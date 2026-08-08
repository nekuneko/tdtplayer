// qml/WindowController.qml
import QtQuick
import QtCore

Item {
    id: root

    required property var window
    required property var appSettings
    required property var ctrl

    // Enlaces de sincronización bidireccionales nativos con el motor de persistencia Settings
    Connections {
        target: root.window
        function onXChanged() {
            if (root.window.visibility === Window.Windowed && !root.window.isBooting) {
                root.appSettings.windowX = root.window.x;
            }
        }

        function onYChanged() {
            if (root.window.visibility === Window.Windowed && !root.window.isBooting) {
                root.appSettings.windowY = root.window.y;
            }
        }

        function onWidthChanged() {
            if (root.window.visibility === Window.Windowed && !root.window.isBooting) {
                root.appSettings.windowWidth = root.window.width;
            }
        }

        function onHeightChanged() {
            if (root.window.visibility === Window.Windowed && !root.window.isBooting) {
                root.appSettings.windowHeight = root.window.height;
            }
        }

        function onVisibilityChanged() {
            if (root.window.isBooting)
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
