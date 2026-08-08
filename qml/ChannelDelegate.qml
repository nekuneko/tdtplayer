// qml/ChannelDelegate.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    id: control
    width: parent ? parent.width : (appTheme ? appTheme.px(290) : 290)
    height: appTheme ? appTheme.px(60) : 60
    hoverEnabled: true
    
    required property var sidebarModel
    required property int modelRow
    required property int currentChannelIndex

    signal clickedReal(int realIndex)
    signal hoveredReal(string channelName)

    readonly property int realIndex: (sidebarModel && sidebarModel.rowCount() > 0) ? (modelRow % sidebarModel.rowCount()) : 0
    highlighted: currentChannelIndex === realIndex

    background: Rectangle {
        color: control.highlighted 
               ? appTheme.bgItemActive 
               : (control.hovered ? appTheme.bgItemHover : "transparent") 
        radius: appTheme ? appTheme.px(6) : 6
        border.color: control.highlighted ? appTheme.borderActive : (control.hovered ? appTheme.borderHover : "transparent")
        border.width: 1
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.leftMargin: appTheme ? appTheme.px(16) : 16
        anchors.rightMargin: appTheme ? appTheme.px(16) : 16
        spacing: appTheme ? appTheme.px(12) : 12
        
        Image {
            source: (control.sidebarModel && control.sidebarModel.rowCount() > 0) 
                    ? control.sidebarModel.data(control.sidebarModel.index(control.realIndex, 0), Qt.UserRole + 3) 
                    : ""
            Layout.preferredWidth: appTheme ? appTheme.px(35) : 35
            Layout.preferredHeight: appTheme ? appTheme.px(35) : 35
            fillMode: Image.PreserveAspectFit
            cache: true
            onStatusChanged: if (status === Image.Error) source = "image://theme/media-playback-start"
        }

        Text {
            text: (control.sidebarModel && control.sidebarModel.rowCount() > 0) 
                  ? control.sidebarModel.data(control.sidebarModel.index(control.realIndex, 0), Qt.UserRole + 1) 
                  : ""
            color: control.highlighted ? appTheme.textTitleActive : (control.hovered ? appTheme.textTitle : appTheme.textDesc) 
            font.bold: true
            font.pointSize: appTheme ? appTheme.pt(11) : 11
            renderType: Text.NativeRendering
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        Rectangle {
            id: badgeContainer
            property string chNoStr: (control.sidebarModel && control.sidebarModel.rowCount() > 0) 
                                     ? control.sidebarModel.data(control.sidebarModel.index(control.realIndex, 0), Qt.UserRole + 4) 
                                     : ""
            property string finalChNo: chNoStr !== "" ? chNoStr : control.realIndex.toString()

            color: control.highlighted ? appTheme.bgAbsolute : appTheme.badgeTimeBg
            radius: 4

            Layout.preferredHeight: appTheme ? appTheme.px(24) : 24
            Layout.preferredWidth: channelNumberText.implicitWidth + (appTheme ? appTheme.px(14) : 14)
            Layout.alignment: Qt.AlignVCenter

            Text {
                id: channelNumberText
                anchors.centerIn: parent
                text: parent.finalChNo.padStart(2, '0')
                color: control.highlighted ? appTheme.textTitle : appTheme.badgeTimeText
                font.bold: true
                font.pointSize: appTheme ? appTheme.pt(10) : 10
                renderType: Text.NativeRendering
            }
        }
    }

    onClicked: control.clickedReal(control.realIndex)
    
    onHoveredChanged: {
        if (hovered && (control.sidebarModel && control.sidebarModel.rowCount() > 0)) {
            var name = control.sidebarModel.data(control.sidebarModel.index(control.realIndex, 0), Qt.UserRole + 1)
            if (name !== "") control.hoveredReal(name)
        }
    }
}
