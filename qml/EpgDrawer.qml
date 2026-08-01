// EpgDrawer.qml
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property string channelName: ""
    property string channelNo: ""
    property string hoveredChannelName: ""
    property string epgTitle: ""
    property string epgDescription: ""
    property bool isFullScreen: false
    property bool epgForceOpen: false

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    
    visible: !root.isFullScreen || root.epgForceOpen
    height: visible ? 130 : 0 
    hoverEnabled: true
    
    onExited: {
        if (root.isFullScreen) {
            root.epgForceOpen = false
        }
    }

    Behavior on height {
        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
    }

    Rectangle {
        anchors.fill: parent
        color: "#0F172A"
        opacity: 0.95
        border.color: "#3B82F6"
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: (root.hoveredChannelName !== "" ? root.hoveredChannelName : root.channelName) + (root.channelNo !== "" ? " (CH " + root.channelNo.padStart(2, '0') + ")" : "")
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

        Text { text: root.epgTitle; color: "white"; font.bold: true; font.pointSize: 14; Layout.fillWidth: true; elide: Text.ElideRight }
        Text { text: root.epgDescription; color: "#94A3B8"; font.pointSize: 10; Layout.fillWidth: true; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight }
    }
}
