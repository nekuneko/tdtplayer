// qml/ClockWidget.qml
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property var themeItem: typeof appTheme !== "undefined" ? appTheme : null
    property real fontPt: 10
    property int pillHeight: themeItem && themeItem.px ? themeItem.px(24) : 24

    implicitWidth: clockText.implicitWidth + (themeItem && themeItem.px ? themeItem.px(16) : 16)
    implicitHeight: pillHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    radius: themeItem && themeItem.px ? themeItem.px(6) : 6
    color: themeItem ? themeItem.badgeTimeBg : "#1E293B"
    border.color: themeItem ? themeItem.borderHover : "#475569"
    border.width: 1

    property string timeString: "00:00"

    Timer {
        id: clockTimer
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var date = new Date();
            // 🚀 PURGA DE SEGUNDOS: Formateo limpio omitiendo el bloque de segundos
            root.timeString = date.toLocaleTimeString(Qt.locale("es_ES"), "hh:mm");
        }
    }

    onVisibleChanged: {
        if (visible) {
            clockTimer.triggered();
        }
    }

    Text {
        id: clockText
        anchors.centerIn: parent
        text: root.timeString
        color: root.themeItem ? root.themeItem.badgeTimeText : "#60A5FA"
        font.bold: true
        font.pointSize: root.fontPt
        font.family: "Monospace"
        renderType: Text.NativeRendering
    }
}
