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
        interval: 350
        repeat: false
        onTriggered: {
            if (tracker.isPip || tracker.window.visibility === Window.Minimized)
                return;

            if (tracker.pendingPanel === "config"
                    && !tracker.epgDrawerItem.epgForceOpen
                    && !tracker.sidebarItem.visible
                    && !tracker.configSidebarItem.visible) {
                tracker.controller.openConfigAndCollapseOthers();
                tracker.configSidebarItem.sidebarForceOpen = true;
            } else if (tracker.pendingPanel === "channels"
                    && !tracker.epgDrawerItem.epgForceOpen
                    && !tracker.configSidebarItem.visible
                    && !tracker.sidebarItem.visible) {
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

            if (!tracker.epgDrawerItem.epgForceOpen && !tracker.sidebarItem.visible && !tracker.configSidebarItem.visible && point.position.x <= 26) {
                tracker.scheduleOpen("config");
                return;
            }

            if (!tracker.epgDrawerItem.epgForceOpen && !tracker.configSidebarItem.visible && !tracker.sidebarItem.visible && point.position.x >= (tracker.backdropItem.width - 26)) {
                tracker.scheduleOpen("channels");
                return;
            }

            if (tracker.sidebarItem.visible || tracker.configSidebarItem.visible) {
                tracker.cancelPendingOpen();
                return;
            }

            var epgOpenBoundary = tracker.backdropItem.height - tracker.controller.epgDrawer.height - tracker.cardMargin;
            var epgTriggerBoundary = tracker.backdropItem.height - 44;

            if (tracker.controller.epgDrawer.epgForceOpen) {
                if (point.position.y < (epgOpenBoundary - 10)) {
                    tracker.controller.epgDrawer.epgForceOpen = false;
                }
                tracker.cancelPendingOpen();
            } else {
                if (point.position.y >= epgTriggerBoundary) {
                    tracker.scheduleOpen("epg");
                } else {
                    tracker.cancelPendingOpen();
                }
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
