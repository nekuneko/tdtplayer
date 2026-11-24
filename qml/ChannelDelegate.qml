// qml/ChannelDelegate.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    id: delegateRoot

    readonly property real sideMargin: appThemeItem ? appThemeItem.px(12) : 12
    x: sideMargin
    width: ListView.view ? (ListView.view.width - sideMargin * 2) : 296
    height: appThemeItem ? appThemeItem.px(66) : 66
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

    readonly property var indexObj: delegateRoot.sidebarModel ? delegateRoot.sidebarModel.index(delegateRoot.finalRealIndex, 0) : null
    readonly property string channelName: delegateRoot.sidebarModel ? (delegateRoot.sidebarModel.data(delegateRoot.indexObj, Qt.UserRole + 1) || "") : ""
    readonly property string channelLogo: delegateRoot.sidebarModel ? (delegateRoot.sidebarModel.data(delegateRoot.indexObj, Qt.UserRole + 3) || "") : ""
    readonly property string channelChNo: delegateRoot.sidebarModel ? (delegateRoot.sidebarModel.data(delegateRoot.indexObj, Qt.UserRole + 4) || "") : ""
    readonly property string currentProgramTitle: delegateRoot.sidebarModel ? (delegateRoot.sidebarModel.data(delegateRoot.indexObj, Qt.UserRole + 5) || "") : ""

    readonly property bool isCurrentlyPlaying: delegateRoot.currentChannelIndex === delegateRoot.finalRealIndex

    background: Rectangle {
        radius: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(12) : 12
        border.width: 1
        border.color: delegateRoot.isCurrentlyPlaying
                      ? "#60A5FA"
                      : (delegateRoot.hovered
                         ? (delegateRoot.appThemeItem ? delegateRoot.appThemeItem.borderActive : "#3B82F6")
                         : (delegateRoot.appThemeItem ? delegateRoot.appThemeItem.borderDefault : "#1E293B"))

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: delegateRoot.isCurrentlyPlaying
                       ? "#38BDF8"
                       : (delegateRoot.hovered
                          ? (delegateRoot.appThemeItem ? delegateRoot.appThemeItem.bgItemHover : "#1E293B")
                          : "#11192E")
            }
            GradientStop {
                position: 1.0
                color: delegateRoot.isCurrentlyPlaying
                       ? (delegateRoot.appThemeItem ? delegateRoot.appThemeItem.bgItemActive : "#2563EB")
                       : (delegateRoot.hovered
                          ? (delegateRoot.appThemeItem ? delegateRoot.appThemeItem.bgItemHover : "#1E293B")
                          : "#0F172A")
            }
        }
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
        anchors.leftMargin: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(12) : 12
        anchors.rightMargin: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(12) : 12
        spacing: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(10) : 10

        Rectangle {
            Layout.preferredWidth: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(38) : 38
            Layout.preferredHeight: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(38) : 38
            color: delegateRoot.isCurrentlyPlaying ? "#1A0F172A" : (delegateRoot.appThemeItem ? delegateRoot.appThemeItem.logoBg : "#0B1120")
            radius: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(8) : 8
            Layout.alignment: Qt.AlignVCenter

            // 🚀 DETECTOR REACTIVO LIGERO: Muestra un marcador de texto elegante si el PNG falla
            Text {
                anchors.centerIn: parent
                visible: channelLogoImage.status === Image.Error || delegateRoot.channelLogo === ""
                text: delegateRoot.channelName !== "" ? delegateRoot.channelName.substring(0, 1).toUpperCase() : "📺"
                color: "#FFFFFF"
                font.bold: true
                font.pointSize: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.pt(12) : 12
                renderType: Text.QtRendering
            }

            Image {
                id: channelLogoImage
                anchors.fill: parent
                anchors.margins: 3
                source: delegateRoot.channelLogo
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 76
                sourceSize.height: 76

                // 🚀 PURGA DE CUALIFICADORES: Quitamos el onStatusChanged con los fallbacks de texto rotos
                visible: status === Image.Ready && delegateRoot.channelLogo !== ""
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
                text: delegateRoot.channelName
                color: delegateRoot.isCurrentlyPlaying ? "#FFFFFF" : (delegateRoot.appThemeItem ? delegateRoot.appThemeItem.textTitle : "#FFFFFF")
                font.bold: true
                font.pointSize: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.pt(10.5) : 10.5
                elide: Text.ElideRight
                Layout.fillWidth: true
                renderType: Text.QtRendering
            }

            Text {
                visible: delegateRoot.currentProgramTitle !== ""
                text: delegateRoot.currentProgramTitle
                color: delegateRoot.isCurrentlyPlaying ? "#E0F2FE" : "#93C5FD"
                font.pointSize: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.pt(8.5) : 8.5
                elide: Text.ElideRight
                Layout.fillWidth: true
                renderType: Text.QtRendering
            }
        }

        Rectangle {
            id: channelNumberBadge
            color: delegateRoot.isCurrentlyPlaying ? "#FFFFFF" : (delegateRoot.appThemeItem ? delegateRoot.appThemeItem.bgItemActive : "#2563EB")
            radius: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(8) : 8

            Layout.preferredWidth: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(32) : 32
            Layout.preferredHeight: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.px(32) : 32
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: delegateRoot.channelChNo ? delegateRoot.channelChNo.toString().padStart(2, '0') : delegateRoot.finalRealIndex.toString().padStart(2, '0')
                color: delegateRoot.isCurrentlyPlaying ? "#1D4ED8" : (delegateRoot.appThemeItem ? delegateRoot.appThemeItem.getW3cContrast(channelNumberBadge.color) : "#FFFFFF")
                font.bold: true
                font.pointSize: delegateRoot.appThemeItem ? delegateRoot.appThemeItem.pt(10) : 10
                renderType: Text.QtRendering
            }
        }
    }
}
