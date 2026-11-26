// qml/SidebarHoverSync.qml
import QtQuick

Item {
    id: root

    required property var sidebar
    required property var epgDrawer
    required property var ctrl
    required property var model
    required property var window
    required property var keyboardHandler

    property string pendingHoverName: ""

    function handleHover(name) {
        exitGraceTimer.stop();
        if (root.ctrl.zappingTimer.running || !name)
            return;
        root.pendingHoverName = name.toString().trim().replace(/[\r\n]/g, "");
        debounceHoverTimer.restart();
    }

    function handleExit() {
        if (root.sidebar.containsMouse)
            return;

        debounceHoverTimer.stop();
        root.pendingHoverName = "";
        exitGraceTimer.restart();
    }

    function performFullClose() {
        root.ctrl.cancelPendingZapping();
        root.sidebar.sidebarForceOpen = false;
        root.epgDrawer.epgForceOpen = false;
        root.sidebar.forceCenterScrollSync();
        root.ctrl.osdHoveredChannelName = "";

        var currentIdx = root.model.index(root.ctrl.currentChannelIndex, 0);
        var currentName = root.model.data(currentIdx, Qt.UserRole + 1) || "";
        if (currentName !== "") {
            var cleanCurrentName = currentName.toString().trim().replace(/[\r\n]/g, "");
            root.ctrl.osdChannelLogo = root.window.localLogoCache[cleanCurrentName] || "";
            root.ctrl.osdChannelNo = root.model.data(currentIdx, Qt.UserRole + 4) || root.ctrl.currentChannelIndex.toString();
        }
        var currentEpg = root.model.fetch_current_epg(root.ctrl.osdChannelName);
        if (currentEpg && currentEpg.title !== undefined) {
            root.ctrl.epgTitle = currentEpg.title;
            root.ctrl.epgDescription = currentEpg.description;
        }
        root.keyboardHandler.forceActiveFocus();
    }

    Timer {
        id: exitGraceTimer
        interval: 220
        repeat: false
        onTriggered: {
            if (root.sidebar.containsMouse || (root.epgDrawer && root.epgDrawer.containsMouse))
                return;
            root.performFullClose();
        }
    }

    Timer {
        id: debounceHoverTimer
        interval: 150
        repeat: false
        onTriggered: {
            if (root.pendingHoverName === "")
                return;
            root.ctrl.osdHoveredChannelName = root.pendingHoverName;
            var count = root.model.rowCount(), foundLogo = "", foundChNo = "";

            for (var i = 0; i < count; i++) {
                var idx = root.model.index(i, 0);
                var modelName = root.model.data(idx, Qt.UserRole + 1);
                if (modelName && modelName.toString().trim().replace(/[\r\n]/g, "") === root.pendingHoverName) {
                    foundLogo = root.window.localLogoCache[root.pendingHoverName] || "";
                    foundChNo = root.model.data(idx, Qt.UserRole + 4) || i.toString();
                    break;
                }
            }

            root.ctrl.osdChannelNo = foundChNo;
            root.ctrl.osdChannelLogo = foundLogo;

            var epgData = root.model.fetch_current_epg(root.pendingHoverName);
            if (epgData && epgData.title) {
                root.ctrl.epgTitle = epgData.title;
                root.ctrl.epgDescription = epgData.description || "Sin descripción disponible.";
            } else {
                root.ctrl.epgTitle = "Sin información EPG";
                root.ctrl.epgDescription = "No hay guía de programación disponible para " + root.pendingHoverName + ".";
            }
            root.epgDrawer.epgForceOpen = true;
        }
    }
}
