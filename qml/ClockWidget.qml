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
    
    opacity: 0.0
    Behavior on opacity { NumberAnimation { duration: 250 } }

    // Propiedad dinámica que el Timer modificará en cada segundo
    property string currentTime: "00:00"

    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var date = new Date()
            var hours = date.getHours().toString().padStart(2, '0')
            var minutes = date.getMinutes().toString().padStart(2, '0')
            root.currentTime = hours + ":" + minutes
        }
        // Fuerza la primera carga en el milisegundo cero al arrancar la app
        Component.onCompleted: onTriggered()
    }

    Text {
        anchors.centerIn: parent
        text: root.currentTime
        color: "#FFFFFF"
        font.bold: true
        font.pointSize: 16
        font.family: "Courier New" 
        renderType: Text.NativeRendering
    }
}
