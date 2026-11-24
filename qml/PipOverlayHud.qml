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

    opacity: isHovered ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    // Botón superior derecho: Restaurar ventana normal
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        width: 32
        height: 32
        radius: 16
        color: "#CC0F172A"
        border.color: "#475569"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: "⧉"
            color: "#FFFFFF"
            font.pixelSize: 15
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.windowController.togglePipMode()
        }
    }

    // Barra inferior centrada: Silenciar y Play/Pause
    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 12
        spacing: 12

        Rectangle {
            width: 34
            height: 34
            radius: 17
            color: "#CC0F172A"
            border.color: "#475569"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: root.mediaPlayer.audioOutput && root.mediaPlayer.audioOutput.muted ? "🔇" : "🔊"
                color: "#FFFFFF"
                font.pixelSize: 14
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.controller.toggleMute()
            }
        }

        Rectangle {
            width: 34
            height: 34
            radius: 17
            color: "#CC0F172A"
            border.color: "#475569"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: root.mediaPlayer.playbackState === MediaPlayer.PlayingState ? "⏸" : "▶"
                color: "#FFFFFF"
                font.pixelSize: 13
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.controller.togglePlayback()
            }
        }
    }

    // Esquina inferior derecha para redimensionar el PiP libremente
    MouseArea {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 18
        height: 18
        cursorShape: Qt.SizeFDiagCursor
        onPressed: root.window.startSystemResize(Qt.RightEdge | Qt.BottomEdge)
    }
}
