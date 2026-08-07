// qml/ChannelDelegate.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    id: control
    width: 290
    height: 60
    hoverEnabled: true
    
    required property var sidebarModel
    required property int modelRow
    required property int currentChannelIndex

    signal clickedReal(int realIndex)
    signal hoveredReal(string channelName)

    readonly property int realIndex: (sidebarModel && sidebarModel.rowCount() > 0) ? (modelRow % sidebarModel.rowCount()) : 0
    highlighted: currentChannelIndex === realIndex

    background: Rectangle {
        // 🚀 ENLACE DE PALETA TOTAL: Respeta la configuración acromática o de color global al instante
        color: control.highlighted 
               ? appTheme.bgItemActive 
               : (control.hovered ? appTheme.bgItemHover : "transparent") 
        radius: 6
        border.color: control.highlighted ? appTheme.borderActive : (control.hovered ? appTheme.borderHover : "transparent")
        border.width: 1
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    contentItem: RowLayout {
        width: 255
        anchors.centerIn: parent
        anchors.rightMargin: 15 
        spacing: 12
        
        Image {
            source: (control.sidebarModel && control.sidebarModel.rowCount() > 0) 
                    ? control.sidebarModel.data(control.sidebarModel.index(control.realIndex, 0), Qt.UserRole + 3) 
                    : ""
            sourceSize.width: 35
            sourceSize.height: 35
            Layout.preferredWidth: 35
            Layout.preferredHeight: 35
            fillMode: Image.PreserveAspectFit
            cache: true
            onStatusChanged: {
                if (status === Image.Error) {
                    source = "image://theme/media-playback-start"
                }
            }
        }

        Text {
            text: (control.sidebarModel && control.sidebarModel.rowCount() > 0) 
                  ? control.sidebarModel.data(control.sidebarModel.index(control.realIndex, 0), Qt.UserRole + 1) 
                  : ""
            color: control.highlighted 
                   ? appTheme.textTitleActive 
                   : (control.hovered ? appTheme.textTitle : appTheme.textDesc) 
            font.bold: true
            font.pointSize: 11
            renderType: Text.NativeRendering
            Layout.fillWidth: true
            elide: Text.ElideRight
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Rectangle {
            id: badgeContainer
            property string chNoStr: (control.sidebarModel && control.sidebarModel.rowCount() > 0) 
                                     ? control.sidebarModel.data(control.sidebarModel.index(control.realIndex, 0), Qt.UserRole + 4) 
                                     : ""
            property string finalChNo: chNoStr !== "" ? chNoStr : control.realIndex.toString()

            color: control.highlighted ? appTheme.bgAbsolute : appTheme.badgeTimeBg
            radius: 4

            Layout.preferredHeight: 24
            Layout.preferredWidth: channelNumberText.implicitWidth + 14
            Layout.alignment: Qt.AlignVCenter
            
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                id: channelNumberText
                anchors.centerIn: parent
                text: parent.finalChNo.padStart(2, '0')
                color: control.highlighted ? appTheme.textTitle : appTheme.badgeTimeText
                font.bold: true
                font.pointSize: 10
                renderType: Text.NativeRendering
            }
        }
    }

    onClicked: {
        control.clickedReal(control.realIndex)
    }
    
    onHoveredChanged: {
        if (hovered && (control.sidebarModel && control.sidebarModel.rowCount() > 0)) {
            var name = control.sidebarModel.data(control.sidebarModel.index(control.realIndex, 0), Qt.UserRole + 1);
            if (name !== "") {
                control.hoveredReal(name);
            }
        }
    }
}
