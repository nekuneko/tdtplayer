// qml/PlaybackController.qml
import QtQuick
import QtMultimedia

QtObject {
    id: root

    property var model: null
    property var mediaPlayer: null
    property var sidebar: null
    property var epgDrawer: null

    property int currentChannelIndex: 0
    property int tunedChannelIndex: 0
    property bool isVoluntarilyStopped: false
    property bool isConfigMenuOpen: false
    property bool isMuted: false
    property int currentVolumePercent: 100

    property string osdChannelName: ""
    property string osdChannelLogo: ""
    property string osdChannelNo: ""
    property string osdHoveredChannelName: ""
    property string epgTitle: "Sintonizando..."
    property string epgDescription: "Buscando..."

    property bool backupSidebarVisible: false
    property bool backupEpgVisible: false

    signal channelZappedByKeyboard()
    signal channelTuned()

    property Timer epgAutoHideTimer: Timer {
        interval: 3000
        repeat: false
        onTriggered: {
            if (!root.epgDrawer)
                return;
            var mouseOnEpg = Boolean(root.epgDrawer.containsMouse);
            var mouseOnSidebar = Boolean(root.sidebar && root.sidebar.visible && root.sidebar.containsMouse);
            if (!mouseOnEpg && !mouseOnSidebar) {
                root.epgDrawer.epgForceOpen = false;
            }
        }
    }

    function _executeTune(index) {
        root.tunedChannelIndex = index;
        root.channelTuned();
        if (root.mediaPlayer && root.model && !root.isVoluntarilyStopped) {
            var nextUrl = root.model.get_url_at(index);
            if (root.mediaPlayer.source.toString() !== nextUrl) {
                root.mediaPlayer.stop();
                root.mediaPlayer.source = nextUrl;
            }
            root.mediaPlayer.play();
        }
    }

    property Timer zappingTimer: Timer {
        interval: 750
        running: false
        repeat: false
        onTriggered: root._executeTune(root.currentChannelIndex)
    }

    function syncChannelMetadata(index) {
        if (!root.model || index < 0 || index >= root.model.rowCount())
            return;
        var idx = root.model.index(index, 0);
        root.osdChannelName = root.model.data(idx, Qt.UserRole + 1) || "";
        root.osdChannelNo = root.model.data(idx, Qt.UserRole + 4) || "";

        if (root.osdChannelName !== "") {
            var cleanName = root.osdChannelName.toString().trim().replace(/[\r\n]/g, "");
            root.osdChannelLogo = window.localLogoCache[cleanName] || "";
        } else {
            root.osdChannelLogo = "";
        }

        var epg = root.model.fetch_current_epg(root.osdChannelName);
        root.epgTitle = epg ? epg.title : "Emisión en directo";
        root.epgDescription = epg ? (epg.description || "Sin descripción disponible.") : "...";
    }

    function previewChannel(index) {
        if (!root.model || root.model.rowCount() === 0)
            return;
        var count = root.model.rowCount();
        index = index < 0 ? count - 1 : (index >= count ? 0 : index);
        root.currentChannelIndex = index;
        root.osdHoveredChannelName = "";
        root.syncChannelMetadata(index);
        if (root.sidebar)
            root.sidebar.forceKeyboardScrollSync();
        root.channelZappedByKeyboard();
    }

    function cancelPendingZapping() {
        var wasZapping = root.zappingTimer.running;
        root.zappingTimer.stop();
        if (root.currentChannelIndex !== root.tunedChannelIndex) {
            root.currentChannelIndex = root.tunedChannelIndex;
            root.osdHoveredChannelName = "";
            root.syncChannelMetadata(root.tunedChannelIndex);
            if (root.sidebar)
                root.sidebar.forceCenterScrollSync();
        }
        return wasZapping;
    }

    function playChannel(index, immediate) {
        if (!root.model || root.model.rowCount() === 0)
            return;
        var count = root.model.rowCount();
        index = index < 0 ? count - 1 : (index >= count ? 0 : index);

        // Al cambiar de canal se cancela cualquier pausa previa para reanudar en directo
        root.isVoluntarilyStopped = false;
        root.currentChannelIndex = index;
        root.osdHoveredChannelName = "";

        if (typeof appSettings !== "undefined") {
            appSettings.lastChannelIndex = index;
        }

        root.syncChannelMetadata(index);

        if (root.mediaPlayer) {
            if (immediate) {
                root.zappingTimer.stop();
                root._executeTune(index);
            } else {
                root.zappingTimer.restart();
            }
        } else {
            root.tunedChannelIndex = index;
            root.channelTuned();
        }

        if (root.sidebar)
            root.sidebar.forceKeyboardScrollSync();

        root.epgAutoHideTimer.restart();
        root.channelZappedByKeyboard();
    }

    function playChannelByNumber(numStr) {
        if (!root.model)
            return;
        var count = root.model.rowCount();
        for (var i = 0; i < count; i++) {
            if (root.model.data(root.model.index(i, 0), Qt.UserRole + 4) === numStr)
                return playChannel(i, true);
        }
        var target = parseInt(numStr) - 1;
        if (!isNaN(target) && target >= 0 && target < count)
            playChannel(target, true);
    }

    function applyVolume() {
        if (root.mediaPlayer && root.mediaPlayer.audioOutput) {
            root.mediaPlayer.audioOutput.volume = root.isMuted ? 0.0 : (root.currentVolumePercent / 100.0);
        }
    }

    function changeVolume(delta) {
        if (root.isMuted && delta !== 0) {
            root.isMuted = false;
        }
        root.currentVolumePercent = Math.max(0, Math.min(100, root.currentVolumePercent + delta));
        root.applyVolume();
    }

    function toggleMute() {
        root.isMuted = !root.isMuted;
        root.applyVolume();
    }

    function togglePlayback() {
        if (!root.mediaPlayer || !root.model)
            return;
        root.isVoluntarilyStopped = (root.mediaPlayer.playbackState === MediaPlayer.PlayingState);
        if (root.isVoluntarilyStopped) {
            root.mediaPlayer.pause();
        } else {
            // Si estaba detenido o sin source, recargamos el canal actual en directo
            root.channelTuned();
            var currentUrl = root.model.get_url_at(root.currentChannelIndex);
            if (root.mediaPlayer.source.toString() !== currentUrl) {
                root.mediaPlayer.source = currentUrl;
            }
            root.mediaPlayer.play();
        }
    }

    function openConfigAndCollapseOthers() {
        root.isConfigMenuOpen = true;
        if (!root.sidebar || !root.epgDrawer)
            return;
        root.backupSidebarVisible = root.sidebar.sidebarForceOpen;
        root.backupEpgVisible = root.epgDrawer.epgForceOpen;
        root.sidebar.sidebarForceOpen = false;
        root.epgDrawer.epgForceOpen = false;
    }

    function restorePanelsAfterConfig() {
        root.isConfigMenuOpen = false;
        if (!root.sidebar || !root.epgDrawer)
            return;
        root.sidebar.sidebarForceOpen = root.backupSidebarVisible;
        root.epgDrawer.epgForceOpen = root.backupEpgVisible;
    }
}
