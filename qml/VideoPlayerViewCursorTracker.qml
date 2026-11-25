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

    function resetCursor() {
        if (typeof cursorHelper !== "undefined") {
            cursorHelper.set_hidden(false);
        }
        if (!tracker.isPip) {
            mouseInactivityTimer.restart();
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
            if (tracker.isPip || tracker.window.visibility === Window.Minimized)
                return;

            if (!tracker.epgDrawerItem.epgForceOpen && !tracker.sidebarItem.visible && !tracker.configSidebarItem.visible && point.position.x <= 50) {
                tracker.controller.openConfigAndCollapseOthers();
                tracker.configSidebarItem.sidebarForceOpen = true;
                return;
            }

            if (!tracker.epgDrawerItem.epgForceOpen && !tracker.configSidebarItem.visible && !tracker.sidebarItem.visible && point.position.x >= (tracker.backdropItem.width - 50)) {
                tracker.sidebarItem.sidebarForceOpen = true;
                return;
            }

            // Si el ratón vuelve hacia la izquierda fuera del sidebar, ciérralo al instante
            if (tracker.sidebarItem.sidebarForceOpen && point.position.x < (tracker.backdropItem.width - tracker.sidebarItem.width)) {
                tracker.sidebarItem.sidebarForceOpen = false;
            }

            if (tracker.sidebarItem.visible || tracker.configSidebarItem.visible)
                return;

            var epgTopBoundary = tracker.backdropItem.height - tracker.controller.epgDrawer.height - tracker.cardMargin;
            if (point.position.y >= epgTopBoundary) {
                tracker.controller.epgDrawer.epgForceOpen = true;
            } else if (point.position.y < (epgTopBoundary - 10)) {
                tracker.controller.epgDrawer.epgForceOpen = false;
            }
        }
        onHoveredChanged: {
            if (!hovered) {
                tracker.resetCursor();
            }
        }
    }

    Connections {
        target: tracker.controller.epgDrawer
        function onEpgForceOpenChanged() { tracker.resetCursor(); }
    }
}
