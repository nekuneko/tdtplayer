// qml/EpgProgressRow.qml
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property string epgTitle
    required property int startTimestamp
    required property int stopTimestamp
    required property int currentTimestamp

    function px(v) { return (typeof appTheme !== "undefined" && appTheme) ? appTheme.px(v) : v; }

    readonly property int closeBracketIndex: root.epgTitle.indexOf("]")
    readonly property bool hasTime: root.epgTitle.startsWith("[") && closeBracketIndex !== -1
    readonly property string rawTimeStr: hasTime ? root.epgTitle.substring(1, closeBracketIndex).trim() : ""
    readonly property string formattedTime: rawTimeStr ? rawTimeStr.replace(/\s*-\s*/, " ➔ ") : ""
    readonly property bool isPaused: typeof ctrl !== "undefined" && Boolean(ctrl.isVoluntarilyStopped)

    spacing: 8
    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: true

    ClockWidget {
        themeItem: typeof appTheme !== "undefined" ? appTheme : null
        fontPt: 10
        pillHeight: root.px(24)
        Layout.alignment: Qt.AlignVCenter
    }

    Rectangle {
        id: pausedBadge
        visible: root.isPaused
        color: appTheme.liveBg
        radius: root.px(5)
        Layout.preferredHeight: root.px(24)
        Layout.preferredWidth: pausedContent.implicitWidth + root.px(16)
        Layout.alignment: Qt.AlignVCenter

        readonly property color fgColor: appTheme.liveText

        Row {
            id: pausedContent
            anchors.centerIn: parent
            spacing: 6

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2.5
                Rectangle { width: 2.5; height: 9; radius: 1; color: pausedBadge.fgColor }
                Rectangle { width: 2.5; height: 9; radius: 1; color: pausedBadge.fgColor }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "PAUSADO"
                color: pausedBadge.fgColor
                font.bold: true
                font.letterSpacing: 0.6
                font.pointSize: 9
                renderType: Text.NativeRendering
            }
        }
    }

    Rectangle {
        id: drawerTimeBadge
        visible: root.hasTime
        color: appTheme.bgItemActive
        radius: root.px(5)
        Layout.preferredHeight: root.px(24)
        Layout.preferredWidth: timeText.implicitWidth + root.px(16)
        Layout.alignment: Qt.AlignVCenter

        Text {
            id: timeText
            anchors.centerIn: parent
            text: root.formattedTime
            color: appTheme.getW3cContrast(drawerTimeBadge.color)
            font.bold: true
            font.pointSize: 10
            font.family: "Monospace"
            renderType: Text.NativeRendering
        }
    }

    Rectangle {
        id: drawerProgressBarContainer
        visible: root.hasTime && root.stopTimestamp > root.startTimestamp
        Layout.fillWidth: true
        Layout.minimumWidth: 32
        Layout.preferredHeight: root.px(5)
        Layout.alignment: Qt.AlignVCenter
        color: "#334155"
        radius: 2.5

        readonly property real progressFactor: (root.stopTimestamp > root.startTimestamp)
            ? Math.max(0.0, Math.min(1.0, (root.currentTimestamp - root.startTimestamp) / (root.stopTimestamp - root.startTimestamp)))
            : 0.0

        Rectangle {
            width: parent.width * parent.progressFactor
            height: parent.height
            radius: 2.5
            color: appTheme.borderActive
        }
    }
}
