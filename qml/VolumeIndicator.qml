// qml/VolumeIndicator.qml
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    
    // Propiedades de estado expuestas
    property int volumePercent: 100
    property bool showOsd: false

    // Geometría y posicionamiento estático
    anchors.centerIn: parent
    width: 200
    height: 60
    radius: 10
    color: "#0F172A" 
    border.color: "#3B82F6"
    border.width: 1.5
    
    // Estado de opacidad reactivo
    opacity: root.showOsd ? 0.85 : 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    // ===================================================================
    // 🔊 CONTENEDOR MODULAR: FILA DE AUDIO
    // ===================================================================
    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Módulo 1: Icono dinámico de estado de audio (Mutado o Activo)
        Text {
            // Lógica condicional modularizada de forma puramente declarativa
            readonly property string audioIcon: root.volumePercent === 0 ? "🔇" : "🔊"
            
            text: audioIcon
            font.pointSize: 16
            Layout.alignment: Qt.AlignVCenter
        }

        // Módulo 2: Texto formateado con el porcentaje de volumen
        Text {
            text: "Volumen: " + root.volumePercent + "%"
            color: "#FFFFFF" 
            font.bold: true
            font.pointSize: 13
            
            // Reemplaza los anclajes manuales dentro de Layouts por propiedades nativas de alineación
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
