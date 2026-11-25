// qml/PipWindowController.qml
import QtQuick
import QtCore

Item {
    id: root

    required property var window
    required property var appSettings
    required property var ctrl

    property bool isPipMode: false
    property bool isAdjustingAspect: false
    readonly property real pipAspectRatio: 16.0 / 9.0

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
            savedFullScreen = (root.window.visibility === Window.FullScreen);
            if (savedFullScreen) {
                root.window.visibility = Window.Windowed;
                root.ctrl.isFullScreen = false;
            }
            savedX = root.window.x;
            savedY = root.window.y;
            savedWidth = root.window.width;
            savedHeight = root.window.height;

            if (root.ctrl.sidebar)
                root.ctrl.sidebar.sidebarForceOpen = false;
            if (root.ctrl.epgDrawer)
                root.ctrl.epgDrawer.epgForceOpen = false;

            root.isAdjustingAspect = true;
            isPipMode = true;
            root.window.flags = defaultFlags | Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint;

            var pipW = 420;
            var pipH = 236;
            root.window.width = pipW;
            root.window.height = pipH;
            root.window.x = Math.max(0, Screen.desktopAvailableWidth - pipW - 24);
            root.window.y = Math.max(0, Screen.desktopAvailableHeight - pipH - 24);
            Qt.callLater(function () {
                root.isAdjustingAspect = false;
            });
        } else {
            root.isAdjustingAspect = true;
            isPipMode = false;
            root.window.flags = defaultFlags;

            Qt.callLater(function () {
                root.window.x = savedX;
                root.window.y = savedY;
                root.window.width = savedWidth;
                root.window.height = savedHeight;
                root.isAdjustingAspect = false;

                if (savedFullScreen) {
                    root.window.visibility = Window.FullScreen;
                    root.ctrl.isFullScreen = true;
                }
            });
        }
    }

    Connections {
        target: root.window
        function onXChanged() {
            if (!root.isPipMode && !root.isAdjustingAspect && root.window.visibility === Window.Windowed && !root.window.isBooting) {
                root.appSettings.windowX = root.window.x;
            }
        }

        function onYChanged() {
            if (!root.isPipMode && !root.isAdjustingAspect && root.window.visibility === Window.Windowed && !root.window.isBooting) {
                root.appSettings.windowY = root.window.y;
            }
        }

        function onWidthChanged() {
            if (root.isPipMode) {
                if (root.isAdjustingAspect)
                    return;
                root.isAdjustingAspect = true;
                var minW = 240;
                if (root.window.width < minW)
                    root.window.width = minW;
                root.window.height = Math.round(root.window.width / root.pipAspectRatio);
                root.isAdjustingAspect = false;
            } else if (!root.isAdjustingAspect && root.window.visibility === Window.Windowed && !root.window.isBooting) {
                root.appSettings.windowWidth = root.window.width;
            }
        }

        function onHeightChanged() {
            if (root.isPipMode) {
                if (root.isAdjustingAspect)
                    return;
                root.isAdjustingAspect = true;
                var minH = 135;
                if (root.window.height < minH)
                    root.window.height = minH;
                root.window.width = Math.round(root.window.height * root.pipAspectRatio);
                root.isAdjustingAspect = false;
            } else if (!root.isAdjustingAspect && root.window.visibility === Window.Windowed && !root.window.isBooting) {
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
