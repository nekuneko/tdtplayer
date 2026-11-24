// qml/VideoPlayerView.qml
import QtQuick
import QtQuick.Controls
import QtMultimedia

FocusScope {
    id: scope

    required property var window
    required property var windowController
    required property var controller
    required property var sidebarItem
    required property var epgDrawerItem
    required property var configSidebarItem
    required property var globalKeyboardHandlerItem

    property alias mediaPlayer: mediaPlayer
    readonly property bool isPip: Boolean(windowController && windowController.isPipMode)
    readonly property bool isUhdHdr: videoOutput.sourceRect.height > 1080

    readonly property bool isSidebarOpen: Boolean(sidebarItem && sidebarItem.visible && sidebarItem.sidebarForceOpen)
    readonly property bool isConfigOpen: Boolean(configSidebarItem && configSidebarItem.visible && configSidebarItem.sidebarForceOpen)
    readonly property bool isEpgOpen: Boolean(epgDrawerItem && epgDrawerItem.visible)
    readonly property bool isCardMode: !scope.isPip && (scope.isSidebarOpen || scope.isConfigOpen || scope.isEpgOpen)
    readonly property real cardMargin: (typeof appTheme !== "undefined" && appTheme) ? appTheme.px(12) : 12

    function resetMouseCursor() {
        videoMouseTracker.cursorShape = scope.isPip ? Qt.OpenHandCursor : Qt.ArrowCursor;
        mouseInactivityTimer.restart();
    }

    MediaPlayer {
        id: mediaPlayer
        audioOutput: AudioOutput {}
        videoOutput: videoOutput
    }

    Rectangle {
        id: rootBackdrop
        anchors.fill: parent
        color: scope.isCardMode && typeof appTheme !== "undefined" && appTheme ? appTheme.bgAbsolute : "black"

        HoverHandler { id: containerHover }

        Timer {
            id: mouseInactivityTimer
            interval: scope.isPip ? 1500 : 500
            running: !controller.isVoluntarilyStopped && (controller.epgDrawer ? !controller.epgDrawer.epgForceOpen : true)
            repeat: false
            onTriggered: {
                if (!scope.isPip) {
                    videoMouseTracker.cursorShape = Qt.BlankCursor;
                }
            }
        }

        Connections {
            target: controller.epgDrawer
            function onEpgForceOpenChanged() { scope.resetMouseCursor(); }
        }

        MouseArea {
            id: videoMouseTracker
            anchors.fill: parent
            hoverEnabled: true
            z: 0

            onPositionChanged: {
                scope.resetMouseCursor();
                if (scope.isPip || window.visibility === Window.Minimized || sidebarItem.visible || configSidebarItem.visible)
                    return;

                var epgTopBoundary = rootBackdrop.height - controller.epgDrawer.height - scope.cardMargin;
                if (videoMouseTracker.mouseY >= epgTopBoundary) {
                    controller.epgDrawer.epgForceOpen = true;
                } else if (videoMouseTracker.mouseY < (epgTopBoundary - 10)) {
                    controller.epgDrawer.epgForceOpen = false;
                }
            }
        }

        Rectangle {
            id: videoContainer
            z: 1
            color: "black"

            readonly property real leftInset: scope.isCardMode ? (scope.isConfigOpen ? configSidebarItem.width : scope.cardMargin) : 0
            readonly property real rightInset: scope.isCardMode ? (scope.isSidebarOpen ? sidebarItem.width : scope.cardMargin) : 0
            readonly property real bottomInset: scope.isCardMode ? (scope.cardMargin + (scope.isEpgOpen ? (epgDrawerItem.height + scope.cardMargin) : 0)) : 0

            x: leftInset
            y: scope.isCardMode ? scope.cardMargin : 0
            width: Math.max(100, rootBackdrop.width - leftInset - rightInset)
            height: Math.max(80, rootBackdrop.height - y - bottomInset)

            radius: scope.isCardMode ? ((typeof appTheme !== "undefined" && appTheme) ? appTheme.px(16) : 16) : 0
            border.color: scope.isPip
                          ? ((typeof appTheme !== "undefined" && appTheme) ? appTheme.borderHover : "#334155")
                          : (scope.isCardMode && typeof appTheme !== "undefined" && appTheme ? appTheme.borderDefault : "transparent")
            border.width: (scope.isPip || scope.isCardMode) ? 1 : 0
            clip: true

            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on radius { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            VideoOutput {
                id: videoOutput
                anchors.fill: parent
                anchors.margins: videoContainer.border.width
                fillMode: VideoOutput.PreserveAspectFit
            }
        }

        VideoGesturesLayer {
            anchors.fill: parent
            z: 2
            window: scope.window
            windowController: scope.windowController
            controller: scope.controller
            sidebarItem: scope.sidebarItem
            epgDrawerItem: scope.epgDrawerItem
            configSidebarItem: scope.configSidebarItem
            isPip: scope.isPip
        }

        PipOverlayHud {
            anchors.fill: parent
            z: 3
            visible: scope.isPip
            window: scope.window
            windowController: scope.windowController
            controller: scope.controller
            mediaPlayer: mediaPlayer
            isHovered: containerHover.hovered
        }
    }
}
