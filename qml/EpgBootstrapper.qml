// qml/EpgBootstrapper.qml
import QtQuick
import QtMultimedia

Item {
    id: root

    required property var window
    required property var playerView
    required property var epgDrawer
    required property var ctrl

    readonly property bool isSidebarOpen: Boolean(root.ctrl.sidebar && root.ctrl.sidebar.sidebarForceOpen)

    Connections {
        target: root.playerView.mediaPlayer

        function onPlaybackStateChanged() {
            if (root.playerView.mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                root.ctrl.tunedChannelIndex = root.ctrl.currentChannelIndex;
                if (!root.isSidebarOpen) {
                    keyboardEpgTimer.restart();
                }
            }
        }
    }

    Timer {
        id: keyboardEpgTimer
        interval: 3000
        repeat: false
        onTriggered: {
            if (!root.isSidebarOpen && !root.epgDrawer.containsMouse) {
                root.epgDrawer.epgForceOpen = false;
            }
        }
    }

    function resetTimer() {
        if (!root.isSidebarOpen) {
            keyboardEpgTimer.restart();
        } else {
            keyboardEpgTimer.stop();
        }
    }

    Component.onCompleted: root.window.isBooting = false
}
