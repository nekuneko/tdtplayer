// qml/EpgTimePill.qml
import QtQuick

Rectangle {
    id: root

    required property bool isSelected
    required property bool hasValidTime
    required property string timeTextStr
    required property int stopTime
    required property var themeItem

    signal programExpired

    visible: root.hasValidTime
    color: root.isSelected ? "#FFFFFF" : (root.themeItem ? root.themeItem.bgItemActive : "#3B82F6")

    radius: root.themeItem ? root.themeItem.px(5) : 5
    implicitHeight: root.themeItem ? root.themeItem.px(24) : 24
    implicitWidth: labelText.implicitWidth + (root.themeItem ? root.themeItem.px(14) : 14)

    Timer {
        id: expiryTimer
        interval: 1000
        running: root.visible && root.stopTime > 0
        repeat: true
        onTriggered: {
            var currentTimestamp = Math.floor(Date.now() / 1000);
            if (currentTimestamp >= root.stopTime) {
                expiryTimer.stop();
                root.programExpired();
            }
        }
    }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.timeTextStr
        color: root.isSelected ? (root.themeItem ? root.themeItem.bgItemActive : "#3B82F6") : (root.themeItem ? root.themeItem.getW3cContrast(root.color) : "#FFFFFF")
        font.bold: true
        font.pointSize: root.themeItem ? root.themeItem.pt(10) : 10
        font.family: "Monospace"
        renderType: Text.NativeRendering
    }
}
