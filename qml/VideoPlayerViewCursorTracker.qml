// qml/VideoPlayerViewCursorTracker.qml
import QtQuick

Item {
    id: tracker
    anchors.fill: parent

    required property var backdropItem
    required property var window
    required property var controller
    required property var sidebarItem
    required property var epgDrawerItem
    required property var configSidebarItem
    required property bool isPip
    required property bool isBlockedOpen
    required property real cardMargin

    readonly property bool isPointerInside: rootHoverHandler.hovered
    readonly property real edgeTriggerX: tracker.backdropItem ? Math.max(64, tracker.backdropItem.width * 0.085) : 80
    readonly property real edgeTriggerY: tracker.backdropItem ? Math.max(80, tracker.backdropItem.height * 0.13) : 100


    property point lastMousePos: Qt.point(-1, -1)
    property string pendingPanel: ""

    function resetCursor() {
        if (typeof cursorHelper !== "undefined") {
            cursorHelper.set_hidden(false);
        }
        if (!tracker.isPip) {
            mouseInactivityTimer.restart();
        }
    }

    function scheduleOpen(panelName) {
        if (tracker.pendingPanel === panelName && hoverIntentTimer.running)
            return;
        tracker.pendingPanel = panelName;
        hoverIntentTimer.restart();
    }

    function cancelPendingOpen() {
        tracker.pendingPanel = "";
        hoverIntentTimer.stop();
    }

    Timer {
        id: hoverIntentTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (tracker.isPip || tracker.window.visibility === Window.Minimized)
                return;

            var allClosed = !tracker.epgDrawerItem.epgForceOpen
                            && !tracker.sidebarItem.visible
                            && !tracker.configSidebarItem.visible;

            if (tracker.pendingPanel === "config" && allClosed) {
                tracker.controller.openConfigAndCollapseOthers();
                tracker.configSidebarItem.sidebarForceOpen = true;
            } else if (tracker.pendingPanel === "channels" && allClosed) {
                tracker.sidebarItem.sidebarForceOpen = true;
            } else if (tracker.pendingPanel === "epg"
                       && !tracker.sidebarItem.visible
                       && !tracker.configSidebarItem.visible) {
                tracker.controller.epgDrawer.epgForceOpen = true;
            }
            tracker.pendingPanel = "";
        }
    }

    Timer {
        id: mouseInactivityTimer
        interval: 5000
        running: !tracker.isPip
        repeat: false
        onTriggered: {
            if (!tracker.isPip && !tracker.isBlockedOpen) {
                if (typeof cursorHelper !== "undefined") {
                    cursorHelper.set_hidden(true);
                }
            }
        }
    }

    HoverHandler {
        id: rootHoverHandler
        onPointChanged: {
            var dx = Math.abs(point.position.x - tracker.lastMousePos.x);
            var dy = Math.abs(point.position.y - tracker.lastMousePos.y);
            if (dx < 1 && dy < 1)
                return;
            tracker.lastMousePos = Qt.point(point.position.x, point.position.y);

            tracker.resetCursor();
            if (tracker.isPip || tracker.window.visibility === Window.Minimized) {
                tracker.cancelPendingOpen();
                return;
            }

            var allClosed = !tracker.epgDrawerItem.epgForceOpen
                            && !tracker.sidebarItem.visible
                            && !tracker.configSidebarItem.visible;

            if (allClosed && point.position.x <= tracker.edgeTriggerX) {
                tracker.scheduleOpen("config");
                return;
            }

            if (allClosed && point.position.x >= (tracker.backdropItem.width - tracker.edgeTriggerX)) {
                tracker.scheduleOpen("channels");
                return;
            }

            if (tracker.sidebarItem.visible || tracker.configSidebarItem.visible) {
                tracker.cancelPendingOpen();
                return;
            }

            var epgOpenBoundary = tracker.backdropItem.height - tracker.controller.epgDrawer.height - tracker.cardMargin;
            var epgTriggerBoundary = tracker.backdropItem.height - tracker.edgeTriggerY;

            if (tracker.controller.epgDrawer.epgForceOpen) {
                if (point.position.y < (epgOpenBoundary - tracker.cardMargin)) {
                    tracker.controller.epgDrawer.epgForceOpen = false;
                }
                tracker.cancelPendingOpen();
            } else if (point.position.y >= epgTriggerBoundary) {
                tracker.scheduleOpen("epg");
            } else {
                tracker.cancelPendingOpen();
            }
        }
        onHoveredChanged: {
            if (!hovered) {
                tracker.cancelPendingOpen();
                tracker.resetCursor();
            }
        }
    }

    Connections {
        target: tracker.controller.epgDrawer
        function onEpgForceOpenChanged() { tracker.resetCursor(); }
    }
}
