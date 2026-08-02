// OsdPanel.qml
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    
    // Propiedades de estado expuestas
    property string channelName: ""
    property string channelLogo: ""
    property string channelNo: ""
    property bool isFullScreen: false

    // Dimensiones y estilos estáticos
    width: 380 
    height: 85
    radius: 12
    color: "#1E293B" 
    border.color: "#3B82F6" 
    border.width: 1.5
    
    // Estado de visibilidad animado
    opacity: 0.0 
    Behavior on opacity { NumberAnimation { duration: 300 } }

    // ===================================================================
    // 🎛️ CONTENEDOR MODULAR: FILA DE INFORMACIÓN
    // ===================================================================
    RowLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        // Módulo 1: Renderizado del logotipo del canal
        Image {
            id: channelLogoImage
            source: root.channelLogo // Enlace directo simplificado
            sourceSize.width: 45 
            sourceSize.height: 45
            Layout.preferredWidth: 45
            Layout.preferredHeight: 45
            fillMode: Image.PreserveAspectFit
            
            // Mecanismo de rescate por hardware si la URL falla o está vacía
            onStatusChanged: {
                if (status === Image.Error || root.channelLogo === "") {
                    source = "image://theme/media-playback-start"
                }
            }
        }

        // Módulo 2: Bloque de metadatos de texto
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            
            // Etiqueta del nombre del canal
            Text {
                text: root.channelName
                color: "#FFFFFF"
                font.bold: true
                font.pointSize: 14 
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            
            // Etiqueta del número de canal (Formateada internamente)
            Text {
                // Modularizamos la lógica de formateo en una propiedad de solo lectura
                readonly property string channelLabel: root.channelNo !== "" 
                                                       ? "CH " + root.channelNo.padStart(2, '0') 
                                                       : "Tvheadend Stream"
                
                text: channelLabel
                color: "#94A3B8"
                font.pointSize: 10
            }
        }
    }
}
