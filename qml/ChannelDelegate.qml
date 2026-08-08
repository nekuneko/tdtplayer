// qml/ChannelDelegate.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    id: delegateRoot

    width: ListView.view.width
    height: appThemeItem ? appThemeItem.px(60) : 60
    hoverEnabled: true

    property var sidebarModel
    property int modelRow: 0
    property int currentChannelIndex: 0
    property var appThemeItem: null

    signal clickedReal(int realIndex)
    signal hoveredReal(string channelName)

    readonly property int virtualIndex: delegateRoot.modelRow
    readonly property int realChannelCount: delegateRoot.sidebarModel ? delegateRoot.sidebarModel.rowCount() : 0
    readonly property int finalRealIndex: delegateRoot.realChannelCount > 0 ? (delegateRoot.virtualIndex % delegateRoot.realChannelCount) : 0

    // Reactivamos las propiedades directas enlazadas para que el reciclaje nativo (reuseItems) funcione al vuelo
    readonly property var indexObj: delegateRoot.sidebarModel ? delegateRoot.sidebarModel.index(delegateRoot.finalRealIndex, 0) : null
    readonly property string channelName: delegateRoot.sidebarModel ? (delegateRoot.sidebarModel.data(delegateRoot.indexObj, Qt.UserRole + 1) || "") : ""
    readonly property string channelLogo: delegateRoot.sidebarModel ? (delegateRoot.sidebarModel.data(delegateRoot.indexObj, Qt.UserRole + 3) || "") : ""
    readonly property string channelChNo: delegateRoot.sidebarModel ? (delegateRoot.sidebarModel.data(delegateRoot.indexObj, Qt.UserRole + 4) || "") : ""

    readonly property bool isCurrentlyPlaying: delegateRoot.currentChannelIndex === delegateRoot.finalRealIndex

    background: Rectangle {
        color: delegateRoot.isCurrentlyPlaying ? (delegateRoot.appThemeItem ? delegateRoot.appThemeItem.bgItemActive : "#1D4ED8") : (delegateRoot.hovered ? (delegateRoot.appThemeItem ? delegateRoot.appThemeItem.bgItemHover : "#1E293B") : "transparent")
    }

    onHoveredChanged: {
        if (delegateRoot.hovered && delegateRoot.channelName !== "") {
            delegateRoot.hoveredReal(delegateRoot.channelName);
        }
    }

    onClicked: {
        delegateRoot.clickedReal(delegateRoot.finalRealIndex);
    }

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.leftMargin: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(14) : 14
        anchors.rightMargin: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(14) : 14
        spacing: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(12) : 12

        Rectangle {
            id: logoWrapperContainer
            Layout.preferredWidth: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(35) : 35
            Layout.preferredHeight: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(35) : 35
            color: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.logoBg : "transparent"
            radius: 4
            Layout.alignment: Qt.AlignVCenter

            Image {
                anchors.fill: parent
                anchors.margins: 2
                source: delegateRoot.channelLogo
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 70
                sourceSize.height: 70

                cache: true
                asynchronous: true
                smooth: false
                mipmap: false

                onStatusChanged: {
                    if (status === Image.Error || delegateRoot.channelLogo === "") {
                        source = "image://theme/media-playback-start";
                    }
                }
            }
        }

        Text {
            text: delegateRoot.channelName
            color: delegateRoot.isCurrentlyPlaying ? (delegateRoot.appThemeItem ? delegateRoot.appThemeItem.textTitleActive : "#FFFFFF") : (delegateRoot.appThemeItem ? delegateRoot.appThemeItem.textTitle : "#FFFFFF")
            font.bold: delegateRoot.isCurrentlyPlaying
            font.pointSize: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.pt(11) : 11
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            // 🚀 SOLUCIÓN AL INPUT LAG: Cambiado NativeRendering por QtRendering (Hardware Distance Fields)
            renderType: Text.QtRendering
        }

        Rectangle {
            id: channelNumberBadge
            color: delegateRoot.isCurrentlyPlaying ? "#FFFFFF" : (delegateRoot.appThemeItem ? delegateRoot.appThemeItem.bgItemActive : "#3B82F6")
            radius: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(4) : 4

            Layout.preferredWidth: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(34) : 34
            Layout.preferredHeight: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(34) : 34
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: delegateRoot.channelChNo ? delegateRoot.channelChNo.toString().padStart(2, '0') : delegateRoot.finalRealIndex.toString().padStart(2, '0')
                color: delegateRoot.isCurrentlyPlaying ? (delegateRoot.appThemeItem ? delegateRoot.appThemeItem.bgItemActive : "#3B82F6") : (delegateRoot.appThemeItem ? delegateRoot.appThemeItem.getW3cContrast(channelNumberBadge.color) : "#FFFFFF")
                font.bold: true
                font.pointSize: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.pt(10.5) : 10.5

                // 🚀 SOLUCIÓN AL INPUT LAG: Cambiado NativeRendering por QtRendering (Hardware Distance Fields)
                renderType: Text.QtRendering
            }
        }
    }
}
