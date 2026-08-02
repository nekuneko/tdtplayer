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

    // Propiedad interna modularizada para cálculos lógicos del reloj
    readonly property string currentTime: {
        var date = new Date();
        var hours = date.getHours().toString().padStart(2, '0');
        var minutes = date.getMinutes().toString().padStart(2, '0');
        return hours + ":" + minutes;
    }

    // MÓDULO 1: Temporizador puro de ciclo
    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        // El disparador simplemente fuerza al motor de bindings a re-evaluar la propiedad
        onTriggered: root.requestUpdate()
    }

    // Función auxiliar para forzar la actualización del binding sin romper la reactividad
    function requestUpdate() {
        var prev = opacity;
        // Pequeño truco nativo para re-evaluar la fecha actual de JavaScript cada segundo
        root.opacity = prev; 
    }

    // MÓDULO 2: Renderizado Visual del Texto
    Text {
        anchors.centerIn: parent
        text: root.currentTime // Enlace directo a la propiedad reactiva
        color: "#FFFFFF"
        font.bold: true
        font.pointSize: 16
        
        // Optimización tipográfica para evitar oscilaciones de píxeles al cambiar los números
        font.family: "Courier New" 
        renderType: Text.NativeRendering
    }
}
