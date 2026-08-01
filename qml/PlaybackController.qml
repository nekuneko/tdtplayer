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
    property bool isFullScreen: false
    property bool isVoluntarilyStopped: false
    
    property string osdChannelName: ""
    property string osdChannelLogo: ""
    property string osdChannelNo: ""
    property string osdHoveredChannelName: ""

    property string epgTitle: "Sintonizando canal..."
    property string epgDescription: "Buscando información..."
    
    property int currentVolumePercent: 100
    property bool showVolumeOsd: false
    property real osdPanelOpacity: 0.0

    property Timer osdTimer: Timer { interval: 3000; onTriggered: root.osdPanelOpacity = 0.0 }
    property Timer volumeOsdTimer: Timer { interval: 2000; onTriggered: root.showVolumeOsd = false }
    property Timer epgPoller: Timer { interval: 300; running: false }

    // 🛠️ REPARADO: El temporizador ahora SOLO controla la apertura del vídeo.
    // La guía de televisión (EPG) se desvincula de aquí para que cambie al instante sin esperas.
    property Timer zappingTimer: Timer {
        interval: 250 // Tiempo de cortesía de 250ms para soltar la tecla antes de abrir el vídeo
        running: false
        repeat: false
        onTriggered: {
            if (root.mediaPlayer && root.model && !root.isVoluntarilyStopped) {
                // Sintonización real de red (Sólo cuando el usuario se detiene)
                root.mediaPlayer.source = root.model.get_url_at(root.currentChannelIndex);
                root.mediaPlayer.play();
            }
        }
    }

    function playChannel(index) {
        if (!root.model || root.model.rowCount() === 0) return;
        
        if (index < 0) index = root.model.rowCount() - 1;
        else if (index >= root.model.rowCount()) index = 0;
        
        root.currentChannelIndex = index;
        
        // Paramos inmediatamente el intento de carga de vídeo del canal anterior
        root.zappingTimer.stop();
        
        root.osdHoveredChannelName = "";

        // 1. ACTUALIZACIÓN VISUAL INMEDIATA DE CABECERA (Milisegundo 0)
        root.osdChannelName = root.model.data(root.model.index(index, 0), Qt.UserRole + 1);
        root.osdChannelLogo = root.model.data(root.model.index(index, 0), Qt.UserRole + 3);
        root.osdChannelNo = root.model.data(root.model.index(index, 0), Qt.UserRole + 4);
        
        root.osdTimer.restart();
        root.osdPanelOpacity = 1.0;

        // 🚀 2. ACTUALIZACIÓN INMEDIATA DEL EPG DESDE LA RAM (Milisegundo 0)
        // Como la consulta tarda 0ms, la extraemos directamente al pulsar la tecla.
        // Mientras mantengas pulsadas las flechas, el texto de lo que echan cambiará sincronizado canal por canal.
        var epgData = root.model.fetch_current_epg(root.osdChannelName);
        if (epgData && epgData.title !== undefined) {
            root.epgTitle = epgData.title;
            root.epgDescription = epgData.description || "Sin descripción disponible.";
        } else {
            root.epgTitle = "Emisión en directo";
            root.epgDescription = "Buscando información del evento actual en el flujo de Tvheadend...";
        }

        if (root.mediaPlayer) {
            // Cortamos el flujo de red anterior para que la pantalla no se congele con basura
            root.mediaPlayer.stop();
            root.mediaPlayer.source = "";
            
            if (!root.isVoluntarilyStopped) {
                // Planificamos la sintonización del vídeo
                root.zappingTimer.start();
            } else {
                root.epgTitle = root.epgTitle + " (En Pausa)";
            }
        }

        if (root.sidebar) {
            root.sidebar.forceKeyboardScrollSync();
        }
    }

    function playChannelByNumber(numberStr) {
        if (!root.model) return;
        var count = root.model.rowCount();
        for (var i = 0; i < count; i++) {
            if (root.model.data(root.model.index(i, 0), Qt.UserRole + 4) === numberStr) {
                root.playChannel(i);
                return;
            }
        }
        var targetIndex = parseInt(numberStr) - 1;
        if (!isNaN(targetIndex) && targetIndex >= 0 && targetIndex < count) {
            root.playChannel(targetIndex);
        }
    }

    function changeVolume(delta) {
        root.currentVolumePercent = Math.max(0, Math.min(100, root.currentVolumePercent + delta));
        if (root.mediaPlayer && root.mediaPlayer.audioOutput) {
            root.mediaPlayer.audioOutput.volume = root.currentVolumePercent / 100.0;
        }
        root.volumeOsdTimer.restart();
        root.showVolumeOsd = true;
    }

    function togglePlayback() {
        if (!root.mediaPlayer || !root.model) return;
        if (root.mediaPlayer.playbackState === MediaPlayer.PlayingState) {
            root.isVoluntarilyStopped = true;
            root.mediaPlayer.stop();
            root.mediaPlayer.source = ""; 
        } else {
            root.isVoluntarilyStopped = false;
            root.playChannel(root.currentChannelIndex);
        }
    }

    function forceResume() {
        if (!root.mediaPlayer || !root.model) return;
        if (root.mediaPlayer.playbackState !== MediaPlayer.PlayingState) {
            root.isVoluntarilyStopped = false;
            root.playChannel(root.currentChannelIndex);
        }
    }
}
