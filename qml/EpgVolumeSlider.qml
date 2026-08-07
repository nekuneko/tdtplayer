// qml/EpgVolumeSlider.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    spacing: 8
    Layout.alignment: Qt.AlignVCenter
    
    required property bool isFullScreen

    // 🚀 NUEVO: Botón interactivo de Mute con icono dinámico
    Button {
        id: muteButton
        Layout.preferredWidth: 26
        Layout.preferredHeight: 26
        Layout.alignment: Qt.AlignVCenter
        hoverEnabled: true
        
        onClicked: ctrl.toggleMute()

        // Fondo transparente con indicación de hover moderna
        background: Rectangle {
            color: muteButton.hovered ? "#1E293B" : "transparent"
            radius: 4
        }

        contentItem: Text {
            text: (ctrl.isMuted || ctrl.currentVolumePercent === 0) ? "🔇" : "🔊"
            font.pointSize: root.isFullScreen ? 11 : 10
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    Slider {
        id: volumeSlider
        from: 0
        to: 100
        // Si está en mute, forzamos visualmente la barra a cero de forma reactiva
        value: ctrl.isMuted ? 0 : ctrl.currentVolumePercent
        Layout.preferredWidth: 100
        Layout.preferredHeight: 20
        Layout.alignment: Qt.AlignVCenter

        onMoved: {
            var diff = Math.round(value) - ctrl.currentVolumePercent
            ctrl.changeVolume(diff)
        }

        background: Rectangle {
            x: volumeSlider.leftPadding
            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
            implicitWidth: 100
            implicitHeight: 4
            width: volumeSlider.availableWidth
            height: implicitHeight
            radius: 2
            color: "#334155"

            Rectangle {
                width: volumeSlider.visualPosition * parent.width
                height: parent.height
                color: ctrl.isMuted ? "#64748B" : "#3B82F6" // Color grisáceo si está silenciado
                radius: 2
            }
        }

        handle: Rectangle {
            x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
            implicitWidth: 12
            implicitHeight: 12
            radius: 6
            color: ctrl.isMuted ? "#475569" : (volumeSlider.pressed ? "#60A5FA" : "#3B82F6")
            border.color: "#FFFFFF"
            border.width: 1
        }
    }

    Text {
        text: (ctrl.isMuted ? "0" : ctrl.currentVolumePercent) + "%"
        color: ctrl.isMuted ? "#64748B" : "#94A3B8"
        font.bold: true
        font.pointSize: root.isFullScreen ? 10 : 9
        font.family: "Monospace"
        Layout.preferredWidth: 32
        Layout.alignment: Qt.AlignVCenter
    }
}
