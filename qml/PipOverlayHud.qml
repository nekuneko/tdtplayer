// qml/PipOverlayHud.qml
import QtQuick
import QtMultimedia

Item {
    id: root

    required property var window
    required property var windowController
    required property var controller
    required property var mediaPlayer
    required property bool isHovered

    Item {
        anchors.fill: parent
        opacity: root.isHovered ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        PipIconButton {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 12
            iconType: "restore"
            onClicked: root.windowController.togglePipMode()
        }

        Row {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 12
            spacing: 10

            PipIconButton {
                iconType: "mute"
                isActiveState: root.controller.isMuted || (root.mediaPlayer.audioOutput && root.mediaPlayer.audioOutput.muted)
                onClicked: root.controller.toggleMute()
            }

            PipIconButton {
                iconType: "play"
                isActiveState: root.mediaPlayer.playbackState === MediaPlayer.PlayingState
                onClicked: root.controller.togglePlayback()
            }
        }
    }

    PipResizeHandles {
        anchors.fill: parent
        targetWindow: root.window
    }
}
