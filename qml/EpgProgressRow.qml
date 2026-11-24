// qml/EpgProgressRow.qml
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property bool isFullScreen
    required property string epgTitle
    required property int startTimestamp
    required property int stopTimestamp
    required property int currentTimestamp

    readonly property int closeBracketIndex: root.epgTitle.indexOf("]")
    readonly property bool hasTime: root.epgTitle.startsWith("[") && closeBracketIndex !== -1
    readonly property string rawTimeStr: hasTime ? root.epgTitle.substring(1, closeBracketIndex).trim() : ""
    readonly property string formattedTime: rawTimeStr ? rawTimeStr.replace(/\s*-\s*/, " ➔ ") : ""

    spacing: 8
    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: true

    // Píldora del reloj actual a la izquierda
    ClockWidget {
        themeItem: typeof appTheme !== "undefined" ? appTheme : null
        fontPt: root.isFullScreen ? 11 : 10
        pillHeight: appTheme && appTheme.px ? appTheme.px(24) : 24
        Layout.alignment: Qt.AlignVCenter
    }

    // Píldora de inicio/fin del programa
    Rectangle {
        id: drawerTimeBadge
        visible: root.hasTime
        color: appTheme.bgItemActive
        radius: appTheme && appTheme.px ? appTheme.px(5) : 5
        Layout.preferredHeight: appTheme && appTheme.px ? appTheme.px(24) : 24
        Layout.preferredWidth: timeText.implicitWidth + (appTheme && appTheme.px ? appTheme.px(16) : 16)
        Layout.alignment: Qt.AlignVCenter

        Text {
            id: timeText
            anchors.centerIn: parent
            text: root.formattedTime
            color: appTheme.getW3cContrast(drawerTimeBadge.color)
            font.bold: true
            font.pointSize: root.isFullScreen ? 11 : 10
            font.family: "Monospace"
            renderType: Text.NativeRendering
        }
    }

    // Barra de progreso en directo
    Rectangle {
        id: drawerProgressBarContainer
        visible: root.hasTime && root.stopTimestamp > root.startTimestamp && width > 24
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.preferredHeight: appTheme && appTheme.px ? appTheme.px(4) : 4
        Layout.alignment: Qt.AlignVCenter
        color: "#334155"
        radius: 2

        readonly property real progressFactor: (root.stopTimestamp > root.startTimestamp)
            ? Math.max(0.0, Math.min(1.0, (root.currentTimestamp - root.startTimestamp) / (root.stopTimestamp - root.startTimestamp)))
            : 0.0

        Rectangle {
            width: parent.width * parent.progressFactor
            height: parent.height
            radius: 2
            color: appTheme.borderActive
        }
    }
}
