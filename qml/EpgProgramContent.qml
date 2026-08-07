// qml/EpgProgramContent.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 20

    required property bool isFullScreen
    required property string channelLogo
    required property string epgTitle
    required property string epgDescription

    WheelHandler {
        id: contentScrollShield
        orientation: Qt.Vertical
        onWheel: (event) => {
            if (descFlickable.visible) {
                if (event.angleDelta.y > 0) {
                    descFlickable.contentY = Math.max(0, descFlickable.contentY - 25)
                } else {
                    descFlickable.contentY = Math.min(descFlickable.contentHeight - descFlickable.height, descFlickable.contentY + 25)
                }
            }
            event.accepted = true
        }
    }

    Rectangle {
        Layout.preferredWidth: 60
        Layout.preferredHeight: 60
        color: "#1E293B"
        radius: 8
        Layout.alignment: Qt.AlignTop

        Image {
            anchors.fill: parent
            anchors.margins: 4
            source: root.channelLogo
            fillMode: Image.PreserveAspectFit
            onStatusChanged: if (status === Image.Error || root.channelLogo === "") source = "image://theme/media-playback-start"
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 4

        readonly property var timeMatch: root.epgTitle.match(/^\[(\d{2}:\d{2}\s*-\s*\d{2}:\d{2})\]\s*(.*)$/)
        readonly property bool hasTime: timeMatch !== null
        readonly property string extractedTime: hasTime ? timeMatch[1].trim() : ""
        readonly property string cleanTitle: hasTime ? timeMatch[2].trim() : root.epgTitle

        RowLayout {
            visible: parent.hasTime
            spacing: 6
            Layout.fillWidth: true

            Text {
                text: "🕒"
                font.pointSize: root.isFullScreen ? 10 : 9
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: parent.parent.extractedTime
                color: "#94A3B8" 
                font.bold: true
                font.pointSize: root.isFullScreen ? 11 : 10
                font.family: "Monospace"
                Layout.alignment: Qt.AlignVCenter
            }
        }

        Text {
            text: parent.cleanTitle
            color: "#FFFFFF" 
            font.bold: true
            font.pointSize: root.isFullScreen ? 15 : 13
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        Item { Layout.preferredHeight: 2 }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            Flickable {
                id: descFlickable
                anchors.fill: parent
                contentWidth: width
                contentHeight: descriptionText.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Text {
                    id: descriptionText
                    width: descFlickable.width
                    text: root.epgDescription
                    color: "#64748B" 
                    font.pointSize: root.isFullScreen ? 11 : 10
                    wrapMode: Text.WordWrap
                }

                ScrollBar.vertical: ScrollBar {
                    id: verticalScrollBar
                    policy: descFlickable.contentHeight > descFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                    
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: "#475569"
                    }
                }
            }
        }
    }
}
