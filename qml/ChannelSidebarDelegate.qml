// qml/ChannelSidebarDelegate.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    id: delegateRoot

    x: 0
    width: ListView.view ? ListView.view.width : 300
    height: appThemeItem ? appThemeItem.px(64) : 64
    hoverEnabled: true

    required property int index
    required property string name
    required property string logo
    required property string chNo
    required property string epgTitle

    property var sidebarModel
    property int currentChannelIndex: 0
    property var appThemeItem: null

    signal clickedReal(int realIndex)
    signal hoveredReal(string channelName)

    readonly property int realChannelCount: delegateRoot.sidebarModel ? delegateRoot.sidebarModel.rowCount() : 0
    readonly property int finalRealIndex: delegateRoot.realChannelCount > 0 ? (delegateRoot.index % delegateRoot.realChannelCount) : 0
    readonly property bool isCurrentlyPlaying: delegateRoot.currentChannelIndex === delegateRoot.finalRealIndex

    background: Rectangle {
        radius: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(10) : 10
        border.width: 1
        border.color: delegateRoot.appThemeItem
                      ? (delegateRoot.isCurrentlyPlaying
                         ? delegateRoot.appThemeItem.borderActive
                         : (delegateRoot.hovered ? delegateRoot.appThemeItem.borderHover : delegateRoot.appThemeItem.borderDefault))
                      : "#1E293B"
        color: delegateRoot.appThemeItem
               ? (delegateRoot.isCurrentlyPlaying
                  ? delegateRoot.appThemeItem.bgItemActive
                  : (delegateRoot.hovered ? delegateRoot.appThemeItem.bgItemHover : delegateRoot.appThemeItem.bgItemDefault))
               : "#0B0F19"
    }

    onHoveredChanged: {
        if (delegateRoot.hovered && delegateRoot.name !== "") {
            delegateRoot.hoveredReal(delegateRoot.name);
        }
    }

    onClicked: {
        delegateRoot.clickedReal(delegateRoot.finalRealIndex);
    }

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.leftMargin: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(12) : 12
        anchors.rightMargin: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(12) : 12
        spacing: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(12) : 12

        Rectangle {
            Layout.preferredWidth: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(36) : 36
            Layout.preferredHeight: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(36) : 36
            color: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.logoBg : "transparent"
            radius: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(8) : 8
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                visible: channelLogoImage.status === Image.Error || delegateRoot.logo === ""
                text: delegateRoot.name !== "" ? delegateRoot.name.substring(0, 1).toUpperCase() : "📺"
                color: delegateRoot.appThemeItem
                       ? (delegateRoot.isCurrentlyPlaying ? delegateRoot.appThemeItem.textTitleActive : delegateRoot.appThemeItem.textTitle)
                       : "#FFFFFF"
                font.bold: true
                font.pointSize: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.pt(12) : 12
                renderType: Text.QtRendering
            }

            Image {
                id: channelLogoImage
                anchors.fill: parent
                anchors.margins: 2
                source: delegateRoot.logo
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 72
                sourceSize.height: 72
                visible: status === Image.Ready && delegateRoot.logo !== ""
                cache: true
                asynchronous: true
                smooth: false
                mipmap: false
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(2) : 2

            Text {
                text: delegateRoot.name
                color: delegateRoot.appThemeItem
                       ? (delegateRoot.isCurrentlyPlaying ? delegateRoot.appThemeItem.textTitleActive : delegateRoot.appThemeItem.textTitle)
                       : "#FFFFFF"
                font.bold: true
                font.pointSize: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.pt(10.5) : 10.5
                elide: Text.ElideRight
                Layout.fillWidth: true
                renderType: Text.QtRendering
            }

            Text {
                visible: delegateRoot.epgTitle !== ""
                text: delegateRoot.epgTitle
                color: delegateRoot.appThemeItem
                       ? (delegateRoot.isCurrentlyPlaying ? delegateRoot.appThemeItem.textDescActive : delegateRoot.appThemeItem.textDesc)
                       : "#CBD5E1"
                font.pointSize: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.pt(8.5) : 8.5
                elide: Text.ElideRight
                Layout.fillWidth: true
                renderType: Text.QtRendering
            }
        }

        Rectangle {
            id: channelNumberBadge
            color: delegateRoot.appThemeItem
                   ? (delegateRoot.isCurrentlyPlaying ? delegateRoot.appThemeItem.textTitleActive : delegateRoot.appThemeItem.bgItemActive)
                   : "#1D4ED8"
            radius: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(8) : 8

            Layout.preferredWidth: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(32) : 32
            Layout.preferredHeight: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(32) : 32
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: delegateRoot.chNo ? delegateRoot.chNo.toString().padStart(2, '0') : delegateRoot.finalRealIndex.toString().padStart(2, '0')
                color: delegateRoot.appThemeItem
                       ? delegateRoot.appThemeItem.getW3cContrast(channelNumberBadge.color)
                       : "#FFFFFF"
                font.bold: true
                font.pointSize: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.pt(10) : 10
                renderType: Text.QtRendering
            }
        }
    }
}
