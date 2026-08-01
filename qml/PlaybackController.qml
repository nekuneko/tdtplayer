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

    // 🛠️ REPARADO: El poller ahora pide los datos en segundo plano de forma no bloqueante
    property Timer epgPoller: Timer {
        interval: 300 
        onTriggered: {
            if (root.osdChannelName !== "" && root.model) {
                root.model.request_epg_async(root.osdChannelName);
            }
        }
    }

    // 👇 NUEVO: Temporizador para retrasar la sintonización del flujo de vídeo (1.2 segundos)
    property Timer zappingTimer: Timer {
        interval: 350
        running: false
        repeat: false
        onTriggered: {
            if (root.mediaPlayer && root.model && !root.isVoluntarilyStopped) {
                // Aquí se realiza la sintonización real de red de forma segura
                root.mediaPlayer.source = root.model.get_url_at(root.currentChannelIndex);
                root.mediaPlayer.play();
                root.epgPoller.restart();
            }
        }
    }

    // Propiedad puente para la UI
    property real osdPanelOpacity: 0.0

    // Métodos de reproducción nucleares
    function playChannel(index) {
        if (!root.model || root.model.rowCount() === 0) return;
        
        if (index < 0) index = root.model.rowCount() - 1;
        else if (index >= root.model.rowCount()) index = 0;
        
        root.currentChannelIndex = index;
        root.zappingTimer.stop();
        
        // 1. PRIORIDAD MÁXIMA: Actualización de UI instantánea
        root.osdChannelName = root.model.data(root.model.index(index, 0), Qt.UserRole + 1);
        root.osdChannelLogo = root.model.data(root.model.index(index, 0), Qt.UserRole + 3);
        root.osdChannelNo = root.model.data(root.model.index(index, 0), Qt.UserRole + 4);
        
        root.osdTimer.restart();
        root.osdPanelOpacity = 1.0;

        // Limpieza visual inmediata antes de que llegue el EPG real del hilo secundario
        root.epgTitle = "Cargando guía...";
        root.epgDescription = "Solicitando datos de emisión a Tvheadend...";

        if (root.mediaPlayer) {
            // Cancelación inmediata del buffer multimedia anterior
            root.mediaPlayer.stop();
            root.mediaPlayer.source = "";
            
            if (!root.isVoluntarilyStopped) {
                root.epgTitle = "Previsualizando canal...";
                root.zappingTimer.start(); // El debounce ágil (ej. 350ms)
            }
        }
        
        // Dispara la petición de red en el hilo de Python
        root.model.request_epg_async(root.osdChannelName);
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
            
            // 👇 REPARADO: Al detener, vaciamos la fuente para cerrar la conexión de red
            root.mediaPlayer.stop();
            root.mediaPlayer.source = ""; 
        } else {
            root.isVoluntarilyStopped = false;
            
            // 👇 REPARADO: Al reanudar, recargamos la URL original para forzar un enganche limpio
            root.mediaPlayer.source = root.model.get_url_at(root.currentChannelIndex);
            root.mediaPlayer.play();
        }
    }

    function forceResume() {
        if (!root.mediaPlayer || !root.model) return;
        
        if (root.mediaPlayer.playbackState !== MediaPlayer.PlayingState) {
            root.isVoluntarilyStopped = false;
            
            // 👇 REPARADO: Aplicamos la misma sintonización limpia si se pulsa Enter/Return
            root.mediaPlayer.source = root.model.get_url_at(root.currentChannelIndex);
            root.mediaPlayer.play();
        }
    }
}
