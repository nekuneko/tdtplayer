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

    // Propiedad expuesta enlazada al detector de ratón de fondo
    readonly property bool containsMouse: epgMouseTracker.containsMouse

    height: root.isFullScreen ? 180 : 160 
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.left: parent ? parent.left : undefined
    
    color: "#0F172A" 
    opacity: 0.96
    border.color: "#3B82F6"
    border.width: root.isFullScreen ? 1 : 0

    Behavior on height {
        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
    }

    // ⏱️ TEMPORIZADOR DE TOLERANCIA OPTIMIZADO
    Timer {
        id: safetyExitTimer
        interval: 200 
        running: false
        repeat: false
        onTriggered: {
            root.epgForceOpen = false
        }
    }

    // 🛡️ GESTOR DE ENTRADA BLINDADO
    MouseArea {
        id: epgMouseTracker
        anchors.fill: parent
        hoverEnabled: true
        z: -1 
        cursorShape: Qt.ArrowCursor
        
        onEntered: {
            safetyExitTimer.stop()
        }
        
        onExited: {
            safetyExitTimer.start()
        }
        
        onPositionChanged: {
            if (typeof playerView !== "undefined") {
                playerView.resetMouseCursor()
            }
        }
    }

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
