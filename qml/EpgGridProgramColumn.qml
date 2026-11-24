// qml/EpgGridProgramColumn.qml
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property string cleanTitle
    required property string finalDesc
    required property bool hasTime
    required property string formattedTime
    required property int startTimestamp
    required property int stopTimestamp
    required property int currentTimestamp
    required property string viewMode
    required property bool isCurrent
    required property var themeItem

    signal programExpired

    Layout.fillWidth: true
    Layout.minimumWidth: 0
    Layout.alignment: Qt.AlignVCenter
    spacing: root.themeItem ? root.themeItem.px(6) : 6

    RowLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        spacing: root.themeItem ? root.themeItem.px(10) : 10
        Layout.alignment: Qt.AlignVCenter

        EpgTimePill {
            isSelected: root.isCurrent
            hasValidTime: root.hasTime
            timeTextStr: root.formattedTime
            stopTime: root.stopTimestamp
            themeItem: root.themeItem
            Layout.alignment: Qt.AlignVCenter
            onProgramExpired: root.programExpired()
        }

        Text {
            text: root.cleanTitle
            color: root.isCurrent ? root.themeItem.textTitleActive : root.themeItem.textTitle
            font.bold: true
            font.pointSize: root.themeItem ? root.themeItem.pt(11.5) : 11.5
            renderType: Text.NativeRendering
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Rectangle {
        id: gridProgressBarContainer
        visible: root.hasTime && root.viewMode === "NOW"
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.preferredHeight: root.themeItem ? root.themeItem.px(3) : 3
        color: root.isCurrent ? Qt.alpha(root.themeItem.textTitleActive, 0.3) : root.themeItem.borderHover
        radius: 2

        readonly property real progressFactor: (root.stopTimestamp > root.startTimestamp)
            ? Math.max(0.0, Math.min(1.0, (root.currentTimestamp - root.startTimestamp) / (root.stopTimestamp - root.startTimestamp)))
            : 0.0

        Rectangle {
            width: gridProgressBarContainer.width * gridProgressBarContainer.progressFactor
            height: parent.height
            radius: 2
            color: root.isCurrent ? root.themeItem.textTitleActive : root.themeItem.borderActive
        }
    }

    Text {
        text: root.finalDesc
        color: root.isCurrent ? root.themeItem.textDescActive : root.themeItem.textDesc
        font.pointSize: root.themeItem ? root.themeItem.pt(9.5) : 9.5
        renderType: Text.NativeRendering
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
    }
}
