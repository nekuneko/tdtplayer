// qml/EpgDrawer.qml
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    
    // Propiedades de estado expuestas
    property string channelName: ""
    property string channelNo: ""
    property string hoveredChannelName: ""
    property string epgTitle: ""
    property string epgDescription: ""
    property bool isFullScreen: false
    property bool epgForceOpen: false
    property var sidebarItem: null

    // Anclajes dinámicos según el estado del panel lateral
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.right: (sidebarItem && sidebarItem.visible && (sidebarItem.width > 0)) 
                   ? sidebarItem.left 
                   : parent.right
    
    visible: !root.isFullScreen || root.epgForceOpen
    height: visible ? 130 : 0 
    hoverEnabled: true
    
    onExited: {
        root.epgForceOpen = false
        
    }

    // Animaciones de interfaz suaves
    Behavior on height {
        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
    }

    Behavior on anchors.right {
        AnchorAnimation { duration: 200; easing.type: Easing.OutQuad }
    }

    // Sub-componente 1: Fondo visual contenedor
    Rectangle {
        id: backgroundContainer
        anchors.fill: parent
        color: "#0F172A"
        opacity: 0.95
        border.color: "#3B82F6"
        border.width: 1
    }

    // Estructura modular del contenido
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 6

        // Sub-componente 2: Fila de cabecera (Meta-información del canal y EPG)
        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            
            Text {
                // Lógica de visualización limpia usando un alias dinámico
                readonly property string targetedChannel: root.hoveredChannelName !== "" ? root.hoveredChannelName : root.channelName
                readonly property string formattedChNo: root.channelNo !== "" ? " (CH " + root.channelNo.padStart(2, '0') + ")" : ""
                
                text: targetedChannel + formattedChNo
                color: "#3B82F6" 
                font.bold: true
                font.pointSize: 10
            }
            
            Text {
                text: " • GUÍA DE PROGRAMACIÓN (EPG)"
                color: "#64748B"
                font.pointSize: 9
            }
        }

        // Sub-componente 3: Título de la emisión actual
        Text {
            id: programTitleText
            text: root.epgTitle
            color: "white"
            font.bold: true
            font.pointSize: 14
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        // Sub-componente 4: Descripción o resumen detallado
        Text {
            id: programDescriptionText
            text: root.epgDescription
            color: "#94A3B8"
            font.pointSize: 10
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }
}
