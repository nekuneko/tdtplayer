// qml/ClockWidget.qml
import QtQuick

Rectangle {
    id: root
    width: 110
    height: 45
    radius: 10
    color: "#1E293B"
    border.color: "#3B82F6"
    border.width: 1.5
    
    // Vinculamos su opacidad a la del OSD superior izquierdo
    opacity: 0.0
    Behavior on opacity { NumberAnimation { duration: 250 } }

    property string timeStr: "00:00"

    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var date = new Date();
            var hours = date.getHours().toString().padStart(2, '0');
            var minutes = date.getMinutes().toString().padStart(2, '0');
            root.timeStr = hours + ":" + minutes;
        }
        Component.onCompleted: onTriggered()
    }

    Text {
        anchors.centerIn: parent
        text: root.timeStr
        color: "white"
        font.bold: true
        font.pointSize: 16
        font.family: "Monospace"
    }
}
