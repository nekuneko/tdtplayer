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

    readonly property bool isMutedNow: root.controller.isMuted || (root.mediaPlayer.audioOutput && root.mediaPlayer.audioOutput.muted)
    readonly property bool isPausedNow: root.controller.isVoluntarilyStopped || root.mediaPlayer.playbackState !== MediaPlayer.PlayingState
    readonly property bool effectiveHovered: root.isHovered || restoreBtn.isHovered || muteBtn.isHovered || playBtn.isHovered

    Item {
        anchors.fill: parent
        opacity: (root.effectiveHovered || root.isMutedNow || root.isPausedNow) ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        PipIconButton {
            id: restoreBtn
            visible: root.effectiveHovered
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
                id: muteBtn
                visible: root.effectiveHovered || root.isMutedNow
                iconType: "mute"
                isActiveState: root.isMutedNow
                isAlert: root.isMutedNow
                onClicked: root.controller.toggleMute()
            }

            PipIconButton {
                id: playBtn
                visible: root.effectiveHovered || root.isPausedNow
                iconType: "play"
                isActiveState: !root.isPausedNow
                isAlert: root.isPausedNow
                onClicked: root.controller.togglePlayback()
            }
        }
    }

    PipResizeHandles {
        anchors.fill: parent
        targetWindow: root.window
    }
}
