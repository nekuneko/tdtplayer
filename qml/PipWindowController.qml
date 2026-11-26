// qml/PipWindowController.qml
import QtQuick

Item {
    id: root

    required property var window
    required property var appSettings
    required property var ctrl

    property bool isPipMode: false
    property bool isAdjustingAspect: false
    readonly property real pipAspectRatio: 16.0 / 9.0
    readonly property bool canPersistGeometry: !root.isPipMode
                                               && !root.isAdjustingAspect
                                               && root.window.visibility === Window.Windowed
                                               && !root.window.isBooting

    property int savedX: 100
    property int savedY: 100
    property int savedWidth: 1024
    property int savedHeight: 768
    property bool savedFullScreen: false
    property int defaultFlags: 0

    Component.onCompleted: defaultFlags = root.window.flags

    function enforcePipAspect(byWidth) {
        if (root.isAdjustingAspect)
            return;
        root.isAdjustingAspect = true;
        if (byWidth) {
            if (root.window.width < 240)
                root.window.width = 240;
            root.window.height = Math.round(root.window.width / root.pipAspectRatio);
        } else {
            if (root.window.height < 135)
                root.window.height = 135;
            root.window.width = Math.round(root.window.height * root.pipAspectRatio);
        }
        root.isAdjustingAspect = false;
    }

    function togglePipMode(enterFullScreen) {
        if (!isPipMode) {
            savedFullScreen = (root.window.visibility === Window.FullScreen);
            if (savedFullScreen) {
                root.window.visibility = Window.Windowed;
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
            Qt.callLater(function () { root.isAdjustingAspect = false; });
        } else {
            root.isAdjustingAspect = true;
            isPipMode = false;
            root.window.flags = defaultFlags;

            var goFullScreen = Boolean(enterFullScreen) || savedFullScreen;

            Qt.callLater(function () {
                root.window.x = savedX;
                root.window.y = savedY;
                root.window.width = savedWidth;
                root.window.height = savedHeight;
                root.isAdjustingAspect = false;

                if (goFullScreen) {
                    root.window.visibility = Window.FullScreen;
                }
            });
        }
    }

    Connections {
        target: root.window
        function onXChanged() {
            if (root.canPersistGeometry)
                root.appSettings.windowX = root.window.x;
        }
        function onYChanged() {
            if (root.canPersistGeometry)
                root.appSettings.windowY = root.window.y;
        }
        function onWidthChanged() {
            if (root.isPipMode) {
                root.enforcePipAspect(true);
            } else if (root.canPersistGeometry) {
                root.appSettings.windowWidth = root.window.width;
            }
        }
        function onHeightChanged() {
            if (root.isPipMode) {
                root.enforcePipAspect(false);
            } else if (root.canPersistGeometry) {
                root.appSettings.windowHeight = root.window.height;
            }
        }
        function onVisibilityChanged() {
            if (root.window.isBooting || root.isPipMode)
                return;
            if (root.window.visibility === Window.FullScreen || root.window.visibility === Window.Windowed) {
                root.appSettings.lastIsFullScreen = (root.window.visibility === Window.FullScreen);
            }
        }
    }
}
