// qml/PlaybackController.qml
import QtQuick
import QtMultimedia

QtObject {
    id: root

    // Propiedades de Estado Globales
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

    // REPARADO: Se eliminó el prefijo inválido 'property timer' y se usa el tipo nativo 'Timer'
    property Timer osdTimer: Timer {
        interval: 3000
        onTriggered: root.osdPanelOpacity = 0.0
    }

    property Timer volumeOsdTimer: Timer {
        interval: 2000
        onTriggered: root.showVolumeOsd = false
    }

    property Timer epgPoller: Timer {
        interval: 300 
        onTriggered: {
            if (root.osdChannelName !== "" && root.model) {
                // 👇 REPARADO: Almacenamos el diccionario devuelto por Python
                var epgData = root.model.fetch_current_epg(root.osdChannelName);
                
                // Extraemos las propiedades mapeadas por nombre de clave
                root.epgTitle = epgData.title;
                root.epgDescription = epgData.description;
            }
        }
    }

    // Propiedad puente para la UI
    property real osdPanelOpacity: 0.0

    // Métodos de reproducción nucleares
    function playChannel(index) {
        if (!root.model || root.model.rowCount() === 0) return;
        
        if (index < 0) index = root.model.model.rowCount() - 1;
        else if (index >= root.model.rowCount()) index = 0;
        
        root.currentChannelIndex = index;
        root.isVoluntarilyStopped = false;
        
        root.epgTitle = "Sintonizando canal...";
        root.epgDescription = "Buscando información del evento actual en el flujo de Tvheadend...";
        
        root.osdChannelName = root.model.data(root.model.index(index, 0), Qt.UserRole + 1);
        root.osdChannelLogo = root.model.data(root.model.index(index, 0), Qt.UserRole + 3);
        root.osdChannelNo = root.model.data(root.model.index(index, 0), Qt.UserRole + 4);
        
        root.osdTimer.restart();
        root.osdPanelOpacity = 1.0;

        if (root.mediaPlayer) {
            root.mediaPlayer.source = root.model.get_url_at(index);
            root.mediaPlayer.play();
        }
        root.epgPoller.restart();
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
        if (!root.mediaPlayer) return;
        if (root.mediaPlayer.playbackState === MediaPlayer.PlayingState) {
            root.isVoluntarilyStopped = true;
            root.mediaPlayer.stop();
        } else {
            root.isVoluntarilyStopped = false;
            root.mediaPlayer.play();
        }
    }

    function forceResume() {
        if (root.mediaPlayer && root.mediaPlayer.playbackState !== MediaPlayer.PlayingState) {
            root.isVoluntarilyStopped = false;
            root.mediaPlayer.play();
        }
    }
}
