// OsdPanel.qml
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string channelName: ""
    property string channelLogo: ""
    property string channelNo: ""
    property bool isFullScreen: false

    width: 380 
    height: 85
    radius: 12
    color: "#1E293B" 
    border.color: "#3B82F6" 
    border.width: 1.5
    opacity: 0.0 
    
    Behavior on opacity { NumberAnimation { duration: 300 } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        Image {
            source: root.channelLogo !== "" ? root.channelLogo : ""
            sourceSize.width: 45 
            sourceSize.height: 45
            Layout.preferredWidth: 45
            Layout.preferredHeight: 45
            fillMode: Image.PreserveAspectFit
            onStatusChanged: {
                if (status === Image.Error) {
                    source = "image://theme/media-playback-start"
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: root.channelName
                color: "white"
                font.bold: true
                font.pointSize: 14 
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                text: root.channelNo !== "" ? "CH " + root.channelNo : "Tvheadend Stream"
                color: "#94A3B8"
                font.pointSize: 10
            }
        }
    }
}
