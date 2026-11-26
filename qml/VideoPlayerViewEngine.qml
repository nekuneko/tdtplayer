// qml/VideoPlayerViewEngine.qml
import QtQuick
import QtMultimedia

Item {
    id: root

    required property var controller
    required property var videoOutput

    signal channelTuneStarted()

    readonly property alias activePlayer: qtPlayer
    readonly property bool canAutoReconnect: !root.controller.isVoluntarilyStopped
                                            && !root.controller.zappingTimer.running
                                            && Boolean(root.controller.model && root.controller.model.rowCount() > 0)

    property int reconnectAttempts: 0

    Connections {
        target: root.controller
        function onTunedChannelIndexChanged() {
            root.reconnectAttempts = 0;
            streamReconnectTimer.stop();
            root.channelTuneStarted();
        }
    }

    Timer {
        id: streamReconnectTimer
        interval: 1200
        repeat: false
        onTriggered: {
            if (root.canAutoReconnect && root.reconnectAttempts < 3) {
                root.reconnectAttempts += 1;
                root.channelTuneStarted();
                var currentUrl = root.controller.model.get_url_at(root.controller.tunedChannelIndex);
                qtPlayer.stop();
                qtPlayer.source = "";
                qtPlayer.source = currentUrl;
                qtPlayer.play();
            }
        }
    }

    MediaDevices {
        id: mediaDevices
        onAudioOutputsChanged: {
            if (qtPlayer.audioOutput) {
                qtPlayer.audioOutput.device = mediaDevices.defaultAudioOutput;
            }
        }
    }

    MediaPlayer {
        id: qtPlayer
        audioOutput: AudioOutput {}
        videoOutput: root.videoOutput

        onAudioTracksChanged: {
            if (audioTracks.length > 0 && activeAudioTrack < 0) {
                activeAudioTrack = 0;
            }
        }

        onMediaStatusChanged: {
            if (root.canAutoReconnect && (mediaStatus === MediaPlayer.EndOfMedia || mediaStatus === MediaPlayer.InvalidMedia)) {
                streamReconnectTimer.restart();
            }
        }

        onErrorOccurred: (error, errorString) => {
            if (root.canAutoReconnect) {
                streamReconnectTimer.restart();
            }
        }
    }
}
