// qml/EpgHeaderRow.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    Layout.fillWidth: true
    spacing: 12

    required property bool isFullScreen
    required property string channelNo
    required property string channelName
    required property string hoveredChannelName

    RowLayout {
        spacing: 8; Layout.alignment: Qt.AlignLeft

        Rectangle {
            visible: root.channelNo !== ""
            color: appTheme.badgeTimeBg
            border.color: appTheme.borderHover; border.width: 1; radius: 4; Layout.preferredWidth: 42; Layout.preferredHeight: 22
            Text {
                anchors.centerIn: parent; text: root.channelNo.padStart(2, '0')
                color: appTheme.textTitle; font.bold: true; font.pointSize: 10; renderType: Text.NativeRendering
            }
        }

        Text {
            text: root.hoveredChannelName !== "" ? root.hoveredChannelName : root.channelName
            color: appTheme.textTitle; font.bold: true; font.pointSize: root.isFullScreen ? 14 : 12; renderType: Text.NativeRendering; elide: Text.ElideRight
        }
    }

    Item { Layout.fillWidth: true }

    RowLayout {
        spacing: 16; Layout.alignment: Qt.AlignRight

        EpgVolumeSlider { isFullScreen: root.isFullScreen }

        Rectangle {
            color: appTheme.liveBg 
            border.color: appTheme.liveBorder; border.width: 1.5; radius: 4
            Layout.preferredHeight: 22; Layout.preferredWidth: liveLabelLayout.implicitWidth + 16 

            RowLayout {
                id: liveLabelLayout; anchors.centerIn: parent; spacing: 6
                Rectangle { width: 6; height: 6; radius: 3; color: appTheme.liveText; Layout.alignment: Qt.AlignVCenter }
                Text { text: "EN DIRECTO AHORA"; color: appTheme.liveText; font.bold: true; font.pointSize: 8; Layout.alignment: Qt.AlignVCenter }
            }
        }
    }
}
