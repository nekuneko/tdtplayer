// qml/VideoPlayerViewEngine.qml
import QtQuick
import QtMultimedia

Item {
    id: root

    required property bool useMpv
    required property var controller
    required property var videoOutput

    readonly property var activePlayer: root.useMpv ? mpvPlayerBridge : fallbackQtPlayer
    property int reconnectAttempts: 0

    Connections {
        target: root.controller
        function onTunedChannelIndexChanged() {
            root.reconnectAttempts = 0;
            streamReconnectTimer.stop();
        }
    }

    Timer {
        id: streamReconnectTimer
        interval: 1200
        repeat: false
        onTriggered: {
            if (!root.useMpv && !root.controller.isVoluntarilyStopped && !root.controller.zappingTimer.running
                    && root.controller.model && root.controller.model.rowCount() > 0
                    && root.reconnectAttempts < 3) {
                root.reconnectAttempts += 1;
                var currentUrl = root.controller.model.get_url_at(root.controller.tunedChannelIndex);
                fallbackQtPlayer.stop();
                fallbackQtPlayer.source = "";
                fallbackQtPlayer.source = currentUrl;
                fallbackQtPlayer.play();
            }
        }
    }

    MediaDevices {
        id: mediaDevices
        onAudioOutputsChanged: {
            if (!root.useMpv && fallbackQtPlayer.audioOutput) {
                fallbackQtPlayer.audioOutput.device = mediaDevices.defaultAudioOutput;
            }
        }
    }

    MediaPlayer {
        id: fallbackQtPlayer
        audioOutput: AudioOutput {}
        videoOutput: root.useMpv ? null : root.videoOutput

        onAudioTracksChanged: {
            if (!root.useMpv && audioTracks.length > 0 && activeAudioTrack < 0) {
                activeAudioTrack = 0;
            }
        }

        onMediaStatusChanged: {
            if (!root.useMpv && (mediaStatus === MediaPlayer.EndOfMedia || mediaStatus === MediaPlayer.InvalidMedia)
                    && !root.controller.isVoluntarilyStopped && !root.controller.zappingTimer.running) {
                streamReconnectTimer.restart();
            }
        }

        onErrorOccurred: (error, errorString) => {
            if (!root.useMpv && !root.controller.isVoluntarilyStopped && !root.controller.zappingTimer.running) {
                streamReconnectTimer.restart();
            }
        }
    }
}
