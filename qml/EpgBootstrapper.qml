// qml/EpgBootstrapper.qml
import QtQuick
import QtMultimedia

Item {
    id: root

    required property var window
    required property var playerView
    required property var epgDrawer
    required property var ctrl

    Connections {
        target: root.playerView.mediaPlayer

        function onPlaybackStateChanged() {
            if (root.playerView.mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                root.ctrl.tunedChannelIndex = root.ctrl.currentChannelIndex;
                // Solo activamos la cuenta atrás si el menú lateral NO está forzado a abrirse
                if (root.ctrl.sidebar && !root.ctrl.sidebar.sidebarForceOpen) {
                    keyboardEpgTimer.restart();
                }
            }
        }
    }

    Timer {
        id: keyboardEpgTimer
        interval: 3000
        repeat: false
        // 🚀 BLOQUEO DE EXPIRACIÓN: Si la barra lateral o el ratón están interactuando, el timer se detiene
        onTriggered: {
            if ((root.ctrl.sidebar && root.ctrl.sidebar.sidebarForceOpen) || root.epgDrawer.containsMouse) {
                return;
            }
            root.epgDrawer.epgForceOpen = false;
        }
    }

    function resetTimer() {
        if (root.ctrl.sidebar && !root.ctrl.sidebar.sidebarForceOpen) {
            keyboardEpgTimer.restart();
        } else {
            keyboardEpgTimer.stop();
        }
    }

    Component.onCompleted: {
        root.window.isBooting = false;
    }
}
