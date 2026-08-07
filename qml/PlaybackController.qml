// qml/PlaybackController.qml
import QtQuick
import QtMultimedia

QtObject {
    id: root

    property var model: null; property var mediaPlayer: null; property var sidebar: null; property var epgDrawer: null
    property int currentChannelIndex: 0; property bool isFullScreen: false; property bool isVoluntarilyStopped: false
    property string osdChannelName: ""; property string osdChannelLogo: ""; property string osdChannelNo: ""; property string osdHoveredChannelName: ""
    property string epgTitle: "Sintonizando..."; property string epgDescription: "Buscando..."
    property int currentVolumePercent: 100; property bool showVolumeOsd: false; property real osdPanelOpacity: 0.0; property bool keyboardActiveOsd: false
    property bool backupSidebarVisible: false; property bool backupEpgVisible: false; property bool isConfigMenuOpen: false

    // Variable de control de silencio nativa
    property bool isMuted: false

    property real clockOpacity: (osdPanelOpacity > 0.0 || (sidebar && sidebar.visible && sidebar.width > 0) || (epgDrawer && epgDrawer.visible && epgDrawer.height > 0)) ? 1.0 : 0.0
    signal channelZappedByKeyboard()

    property Timer osdTimer: Timer { interval: 3000; onTriggered: root.osdPanelOpacity = 0.0 }
    property Timer volumeOsdTimer: Timer { interval: 2000; onTriggered: root.showVolumeOsd = false }
    property Timer epgPoller: Timer { interval: 300; running: false }
    
    property Timer zappingTimer: Timer {
        interval: 250; running: false; repeat: false
        onTriggered: {
            if (root.mediaPlayer && root.model && !root.isVoluntarilyStopped) { 
                root.mediaPlayer.source = root.model.get_url_at(root.currentChannelIndex)
                root.mediaPlayer.play() 
            }
        }
    }

    function playChannel(index) {
        if (!root.model || root.model.rowCount() === 0) return
        var count = root.model.rowCount()
        index = index < 0 ? count - 1 : (index >= count ? 0 : index)
        
        root.currentChannelIndex = index
        root.zappingTimer.stop()
        root.osdHoveredChannelName = ""
        
        if (typeof appSettings !== "undefined") {
            appSettings.lastChannelIndex = index
        }
        
        var idx = root.model.index(index, 0)
        root.osdChannelName = root.model.data(idx, Qt.UserRole + 1) || ""
        root.osdChannelNo = root.model.data(idx, Qt.UserRole + 4) || ""
        
        if (root.osdChannelName !== "") {
            var cleanName = root.osdChannelName.toString().trim().replace(/[\r\n]/g, "");
            root.osdChannelLogo = window.localLogoCache[cleanName] || ""
        } else {
            root.osdChannelLogo = ""
        }
        
        var epg = root.model.fetch_current_epg(root.osdChannelName)
        root.epgTitle = epg ? epg.title : "Emisión en directo"
        root.epgDescription = epg ? (epg.description || "Sin descripción disponible.") : "..."
        
        if (root.mediaPlayer) { 
            root.mediaPlayer.stop()
            if (!root.isVoluntarilyStopped) {
                root.zappingTimer.start() 
            }
        }
        
        if (root.sidebar) root.sidebar.forceKeyboardScrollSync()
        
        root.osdPanelOpacity = 1.0
        root.osdTimer.restart()
        root.channelZappedByKeyboard()
    }

    function playChannelByNumber(numStr) {
        if (!root.model) return
        var count = root.model.rowCount()
        for (var i = 0; i < count; i++) { if (root.model.data(root.model.index(i, 0), Qt.UserRole + 4) === numStr) return playChannel(i) }
        var target = parseInt(numStr) - 1
        if (!isNaN(target) && target >= 0 && target < count) playChannel(target)
    }

    // 🚀 CONTROL DE AUDIO EN HARDWARE CORREGIDO:
    function changeVolume(delta) {
        // Si el usuario sube o baja volumen teniendo el mute puesto, quitamos el silencio de forma intuitiva
        if (root.isMuted && delta !== 0) {
            root.isMuted = false
        }
        root.currentVolumePercent = Math.max(0, Math.min(100, root.currentVolumePercent + delta))
        if (root.mediaPlayer && root.mediaPlayer.audioOutput) {
            // Evaluamos de forma estricta el estado del mute antes de inyectar el float a Qt
            root.mediaPlayer.audioOutput.volume = root.isMuted ? 0.0 : (root.currentVolumePercent / 100.0)
        }
        root.volumeOsdTimer.restart(); root.showVolumeOsd = true
    }

    // 🚀 ALTERNANCIA DE MUTE DIRECTA Y FIABLE:
    function toggleMute() {
        root.isMuted = !root.isMuted
        if (root.mediaPlayer && root.mediaPlayer.audioOutput) {
            // Corta o restituye los decibelios en el mismo milisegundo en la tarjeta de sonido
            root.mediaPlayer.audioOutput.volume = root.isMuted ? 0.0 : (root.currentVolumePercent / 100.0)
        }
        root.volumeOsdTimer.restart(); root.showVolumeOsd = true
    }

    function togglePlayback() {
        if (!root.mediaPlayer || !root.model) return
        root.isVoluntarilyStopped = (root.mediaPlayer.playbackState === MediaPlayer.PlayingState)
        if (root.isVoluntarilyStopped) {
            root.mediaPlayer.pause() 
        } else {
            root.mediaPlayer.play()
        }
    }

    function forceResume() {
        if (root.mediaPlayer && root.model && root.mediaPlayer.playbackState !== MediaPlayer.PlayingState) { root.isVoluntarilyStopped = false; root.mediaPlayer.play() }
    }

    function openConfigAndCollapseOthers() {
        root.isConfigMenuOpen = true; if (!root.sidebar || !root.epgDrawer) return
        root.backupSidebarVisible = root.sidebar.sidebarForceOpen; root.backupEpgVisible = root.epgDrawer.epgForceOpen
        root.sidebar.sidebarForceOpen = false; root.epgDrawer.epgForceOpen = false
    }

    function restorePanelsAfterConfig() {
        root.isConfigMenuOpen = false; if (!root.sidebar || !root.epgDrawer) return
        root.sidebar.sidebarForceOpen = root.backupSidebarVisible; root.epgDrawer.epgForceOpen = root.isFullScreen ? false : root.backupEpgVisible
    }
}
