// qml/PlaybackController.qml
import QtQuick
import QtMultimedia

QtObject {
    id: root

    // Inyección de dependencias y estados de la interfaz
    property var model: null; property var mediaPlayer: null; property var sidebar: null; property var epgDrawer: null
    property int currentChannelIndex: 0; property bool isFullScreen: false; property bool isVoluntarilyStopped: false
    property string osdChannelName: ""; property string osdChannelLogo: ""; property string osdChannelNo: ""; property string osdHoveredChannelName: ""
    property string epgTitle: "Sintonizando..."; property string epgDescription: "Buscando..."
    property int currentVolumePercent: 100; property bool showVolumeOsd: false; property real osdPanelOpacity: 0.0; property bool keyboardActiveOsd: false
    property bool backupSidebarVisible: false; property bool backupEpgVisible: false; property bool isConfigMenuOpen: false

    // Modificadores de visibilidad automáticos y Señales
    property real clockOpacity: (osdPanelOpacity > 0.0 || (sidebar && sidebar.visible && sidebar.width > 0) || (epgDrawer && epgDrawer.visible && epgDrawer.height > 0)) ? 1.0 : 0.0
    signal channelZappedByKeyboard()

    // Temporizadores del OSD y buffer de zapping
    property Timer osdTimer: Timer { interval: 3000; onTriggered: root.osdPanelOpacity = 0.0 }
    property Timer volumeOsdTimer: Timer { interval: 2000; onTriggered: root.showVolumeOsd = false }
    property Timer epgPoller: Timer { interval: 300; running: false }
    property Timer zappingTimer: Timer {
        interval: 250; running: false; repeat: false
        onTriggered: if (root.mediaPlayer && root.model && !root.isVoluntarilyStopped) { root.mediaPlayer.source = root.model.get_url_at(root.currentChannelIndex); root.mediaPlayer.play() }
    }

    // 🚀 LÓGICA DE REPRODUCCIÓN NATIVA COMPACTADA (Sin archivos JS externos)
    function playChannel(index) {
        if (!root.model || root.model.rowCount() === 0) return;
        var count = root.model.rowCount();
        index = index < 0 ? count - 1 : (index >= count ? 0 : index);
        
        root.currentChannelIndex = index; root.zappingTimer.stop(); root.osdHoveredChannelName = "";
        
        var idx = root.model.index(index, 0);
        root.osdChannelName = root.model.data(idx, Qt.UserRole + 1) || "";
        root.osdChannelLogo = root.model.data(idx, Qt.UserRole + 3) || "";
        root.osdChannelNo = root.model.data(idx, Qt.UserRole + 4) || "";
        
        var epg = root.model.fetch_current_epg(root.osdChannelName);
        root.epgTitle = epg ? epg.title : "Emisión en directo";
        root.epgDescription = epg ? (epg.description || "Sin descripción disponible.") : "...";
        
        if (root.mediaPlayer) { root.mediaPlayer.stop(); root.mediaPlayer.source = ""; if (!root.isVoluntarilyStopped) root.zappingTimer.start(); }
        if (root.sidebar) root.sidebar.forceKeyboardScrollSync();
        
        root.osdPanelOpacity = 1.0; root.osdTimer.restart(); root.channelZappedByKeyboard();
    }

    function playChannelByNumber(numStr) {
        if (!root.model) return;
        var count = root.model.rowCount();
        for (var i = 0; i < count; i++) { if (root.model.data(root.model.index(i, 0), Qt.UserRole + 4) === numStr) return playChannel(i); }
        var target = parseInt(numStr) - 1;
        if (!isNaN(target) && target >= 0 && target < count) playChannel(target);
    }

    function changeVolume(delta) {
        root.currentVolumePercent = Math.max(0, Math.min(100, root.currentVolumePercent + delta));
        if (root.mediaPlayer && root.mediaPlayer.audioOutput) root.mediaPlayer.audioOutput.volume = root.currentVolumePercent / 100.0;
        root.volumeOsdTimer.restart(); root.showVolumeOsd = true;
    }

    function togglePlayback() {
        if (!root.mediaPlayer || !root.model) return;
        root.isVoluntarilyStopped = (root.mediaPlayer.playbackState === MediaPlayer.PlayingState);
        if (root.isVoluntarilyStopped) { root.mediaPlayer.stop(); root.mediaPlayer.source = ""; } else { playChannel(root.currentChannelIndex); }
    }

    function forceResume() {
        if (root.mediaPlayer && root.model && root.mediaPlayer.playbackState !== MediaPlayer.PlayingState) { root.isVoluntarilyStopped = false; playChannel(root.currentChannelIndex); }
    }

    function openConfigAndCollapseOthers() {
        root.isConfigMenuOpen = true; if (!root.sidebar || !root.epgDrawer) return;
        root.backupSidebarVisible = root.sidebar.sidebarForceOpen; root.backupEpgVisible = root.epgDrawer.epgForceOpen;
        root.sidebar.sidebarForceOpen = false; root.epgDrawer.epgForceOpen = false;
    }

    function restorePanelsAfterConfig() {
        root.isConfigMenuOpen = false; if (!root.sidebar || !root.epgDrawer) return;
        root.sidebar.sidebarForceOpen = root.backupSidebarVisible; root.epgDrawer.epgForceOpen = root.isFullScreen ? false : root.backupEpgVisible;
    }
}
