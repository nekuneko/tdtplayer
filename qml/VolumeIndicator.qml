// qml/VolumeIndicator.qml
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    
    property int volumePercent: 100
    property bool showOsd: false

    anchors.centerIn: parent
    width: 200
    height: 60
    radius: 10
    color: "#0F172A" 
    border.color: "#3B82F6"
    border.width: 1.5
    
    opacity: root.showOsd ? 0.85 : 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Text {
            // Muestra icono mudo si el controlador está en Mute o el volumen es cero
            readonly property string audioIcon: (ctrl.isMuted || root.volumePercent === 0) ? "🔇" : "🔊"
            text: audioIcon
            font.pointSize: 16
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            // Texto dinámico formateado para el cartel OSD central
            text: ctrl.isMuted ? "Silenciado" : "Volumen: " + root.volumePercent + "%"
            color: "#FFFFFF" 
            font.bold: true
            font.pointSize: 13
            
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
