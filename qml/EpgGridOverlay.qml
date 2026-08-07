// qml/EpgGridOverlay.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: root
    anchors.fill: parent
    visible: false
    opacity: 0.0
    
    objectName: "epgGridOverlayLoader"
    
    property var channelModel
    property int currentChannelIndex
    
    signal channelSelected(int realIndex)
    signal closeRequested()

    Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
    }

    onVisibleChanged: {
        if (visible) {
            root.opacity = 0.92 
            overlayListView.forceActiveFocus()
            if (root.currentChannelIndex >= 0) {
                overlayListView.positionViewAtIndex(root.currentChannelIndex, ListView.Center)
                overlayListView.currentIndex = root.currentChannelIndex
            }
        } else {
            root.opacity = 0.0
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_E) {
            root.closeRequested()
            event.accepted = true
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#030712" 
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onWheel: (event) => event.accepted = true 
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 50 
        spacing: 24

        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "GUÍA DE PROGRAMACIÓN"
                color: "#F8FAFC" 
                font.bold: true
                font.pointSize: 20 
                font.letterSpacing: 3
            }
            
            Item { Layout.fillWidth: true }
            
            Text {
                text: "Pulse 'E' o 'ESC' para volver a la reproducción"
                color: "#94A3B8" 
                font.pointSize: 12
                font.bold: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#334155" 
        }

        ListView {
            id: overlayListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.channelModel
            clip: true
            spacing: 12 
            boundsBehavior: Flickable.StopAtBounds
            focus: true

            // 🚀 DELLEGADO MODULARIZADO EXTRAÍDO
            delegate: EpgGridDelegate {
                channelModel: root.channelModel
                currentChannelIndex: root.currentChannelIndex

                onClicked: {
                    root.channelSelected(itemIndex)
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOn
                contentItem: Rectangle { implicitWidth: 6; radius: 3; color: "#64748B" } 
            }
        }
    }
}
