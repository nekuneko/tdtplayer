// qml/EpgBootstrapper.qml
import QtQuick
import QtMultimedia

Item {
    id: root

    required property var window
    required property var playerView
    required property var epgDrawer
    required property var ctrl

    // Receptor ligado de forma síncrona al backend multimedia de FFmpeg en Qt6
    Connections {
        target: root.playerView.mediaPlayer
        function onPlaybackStateChanged() {
            if (root.playerView.mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                // Detonación bajo demanda: Solo cuando el vídeo brota en pantalla, arranca el temporizador
                keyboardEpgTimer.restart();
            }
        }
    }

    // Reloj asíncrono centralizado para la gestión del retraso OSD
    Timer {
        id: keyboardEpgTimer
        interval: 3000
        onTriggered: root.epgDrawer.epgForceOpen = false
    }

    function resetTimer() {
        keyboardEpgTimer.restart();
    }

    Component.onCompleted: {
        root.window.isBooting = false;
    }
}
