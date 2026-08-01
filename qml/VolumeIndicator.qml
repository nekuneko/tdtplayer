// VolumeIndicator.qml
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
        anchors.margins: 10
        spacing: 10

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            Row {
                anchors.centerIn: parent
                spacing: 12
                Text { text: root.volumePercent === 0 ? "🔇 " : "🔊 "; font.pointSize: 16 }
                Text {
                    text: "Volumen: " + root.volumePercent + "%"
                    color: "white" 
                    font.bold: true
                    font.pointSize: 13
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
