// qml/EpgBadgeNo.qml
import QtQuick

Rectangle {
    id: root

    required property string textNo
    required property bool isSelected
    required property var themeItem

    color: root.isSelected ? "#FFFFFF" : (root.themeItem ? root.themeItem.bgItemActive : "#3B82F6")

    radius: root.themeItem ? root.themeItem.px(6) : 6
    implicitWidth: root.themeItem ? root.themeItem.px(34) : 34
    implicitHeight: root.themeItem ? root.themeItem.px(34) : 34

    Text {
        anchors.centerIn: parent
        text: root.textNo.padStart(2, '0')
        color: root.isSelected ? (root.themeItem ? root.themeItem.bgItemActive : "#3B82F6") : (root.themeItem ? root.themeItem.getW3cContrast(root.color) : "#FFFFFF")
        font.bold: true
        font.pointSize: root.themeItem ? root.themeItem.pt(10.5) : 10.5
        renderType: Text.NativeRendering
    }
}
