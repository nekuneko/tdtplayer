// qml/EpgDrawer.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    
    // Propiedades públicas de la interfaz del componente
    property string channelName: ""
    property string channelNo: ""
    property string hoveredChannelName: ""
    property string channelLogo: "" 
    property string epgTitle: ""
    property string epgDescription: ""
    property bool isFullScreen: false
    property var sidebarItem: null
    property bool epgForceOpen: false

    // Propiedad estructural mantenida por compatibilidad de interfaz
    readonly property bool containsMouse: false

    height: root.isFullScreen ? 180 : 160 
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.left: parent ? parent.left : undefined
    
    color: "#0F172A" 
    opacity: 0.96
    border.color: "#3B82F6"
    border.width: root.isFullScreen ? 1 : 0

    // 🚀 SOLUCIÓN ESTRUCTURAL: Aseguramos que el sistema operativo pinte la flecha de forma nativa en este contenedor
    // sin necesidad de meter interceptores MouseArea invisibles que rompan los clics de los hijos.
    clip: true

    Behavior on height {
        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
    }

    // ❌ ELIMINADOS TODOS LOS DETECTORES DE RATÓN INTERNOS Y TEMPORIZADORES DE PARCHES (MouseArea y safetyExitTimer)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        EpgHeaderRow {
            isFullScreen: root.isFullScreen
            channelNo: root.channelNo
            channelName: root.channelName
            hoveredChannelName: root.hoveredChannelName
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#334155"
        }

        EpgProgramContent {
            isFullScreen: root.isFullScreen
            channelLogo: root.channelLogo
            epgTitle: root.epgTitle
            epgDescription: root.epgDescription
        }
    }

    WheelHandler {
        id: drawerVolumeWheel
        orientation: Qt.Vertical
        onWheel: (event) => {
            if (event.angleDelta.y > 0) {
                ctrl.changeVolume(5)
            } else if (event.angleDelta.y < 0) {
                ctrl.changeVolume(-5)
            }
        }
    }
}
