// qml/VideoPlayerView.qml
import QtQuick

FocusScope {
    id: scope

    required property var window
    required property var windowController
    required property var controller
    required property var sidebarItem
    required property var epgDrawerItem
    required property var configSidebarItem
    required property var globalKeyboardHandlerItem

    readonly property bool useMpv: typeof mpvPlayerBridge !== "undefined" && mpvPlayerBridge !== null
    property alias mediaPlayer: engineAdapter.activePlayer

    readonly property bool isPip: Boolean(windowController && windowController.isPipMode)
    readonly property bool isUhdHdr: videoCard.sourceVideoHeight > 1080
    readonly property bool isSidebarOpen: Boolean(sidebarItem && sidebarItem.visible && sidebarItem.sidebarForceOpen)
    readonly property bool isConfigOpen: Boolean(configSidebarItem && configSidebarItem.visible && configSidebarItem.sidebarForceOpen)
    readonly property bool isEpgOpen: Boolean(epgDrawerItem && epgDrawerItem.visible)
    readonly property bool isCardMode: !scope.isPip && (scope.isSidebarOpen || scope.isConfigOpen || scope.isEpgOpen)
    readonly property real cardMargin: (typeof appTheme !== "undefined" && appTheme) ? appTheme.px(12) : 12

    function resetMouseCursor() {
        cursorController.resetCursor();
    }

    VideoPlayerViewEngine {
        id: engineAdapter
        useMpv: scope.useMpv
        controller: scope.controller
        videoOutput: videoCard.videoOutputItem
    }

    Rectangle {
        id: rootBackdrop
        anchors.fill: parent
        color: scope.isCardMode && typeof appTheme !== "undefined" && appTheme ? appTheme.bgAbsolute : "black"

        VideoPlayerViewCursorTracker {
            id: cursorController
            backdropItem: rootBackdrop
            window: scope.window
            controller: scope.controller
            sidebarItem: scope.sidebarItem
            epgDrawerItem: scope.epgDrawerItem
            configSidebarItem: scope.configSidebarItem
            isPip: scope.isPip
            isBlockedOpen: scope.isSidebarOpen || scope.isConfigOpen || scope.isEpgOpen
            cardMargin: scope.cardMargin
        }

        VideoPlayerViewCard {
            id: videoCard
            z: 1
            isPip: scope.isPip
            isCardMode: scope.isCardMode
            isConfigOpen: scope.isConfigOpen
            isSidebarOpen: scope.isSidebarOpen
            isEpgOpen: scope.isEpgOpen
            configWidth: configSidebarItem ? configSidebarItem.width : 0
            sidebarWidth: sidebarItem ? sidebarItem.width : 0
            epgHeight: epgDrawerItem ? epgDrawerItem.height : 0
            cardMargin: scope.cardMargin
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
            mediaPlayer: scope.mediaPlayer
            isHovered: cursorController.isPointerInside
        }
    }
}
