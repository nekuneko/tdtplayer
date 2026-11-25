// qml/PipIconButton.qml
import QtQuick

Rectangle {
    id: root

    required property string iconType // "restore" | "mute" | "play"
    property bool isActiveState: false
    property bool isAlert: false

    signal clicked

    width: 34
    height: 34
    radius: 10

    readonly property bool isHovered: btnArea.containsMouse
    readonly property color alertBg: appTheme.liveBg
    readonly property color alertFg: appTheme.liveText

    readonly property color fgTint: root.isAlert
                                    ? alertFg
                                    : (isHovered
                                       ? (typeof appTheme !== "undefined" && appTheme ? appTheme.textTitleActive : "#FFFFFF")
                                       : (typeof appTheme !== "undefined" && appTheme ? appTheme.textTitle : "#FFFFFF"))

    color: root.isAlert
           ? alertBg
           : (isHovered
              ? (typeof appTheme !== "undefined" && appTheme ? appTheme.bgItemActive : "#1D4ED8")
              : (typeof appTheme !== "undefined" && appTheme ? appTheme.bgAbsolute : "#CC0B0F17"))
    border.color: root.isAlert
                  ? alertBg
                  : (isHovered
                     ? (typeof appTheme !== "undefined" && appTheme ? appTheme.borderActive : "#60A5FA")
                     : (typeof appTheme !== "undefined" && appTheme ? appTheme.borderDefault : "#1E293B"))
    border.width: 1

    // Icono Restaurar Ventana
    Item {
        visible: root.iconType === "restore"
        anchors.centerIn: parent
        width: 14
        height: 14
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            width: 10; height: 10; radius: 2
            color: "transparent"
            border.color: root.fgTint; border.width: 1.5
        }
        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: 10; height: 10; radius: 2
            color: root.color
            border.color: root.fgTint; border.width: 1.5
        }
    }

    // Icono Pausa (dos barras)
    Row {
        visible: root.iconType === "play" && root.isActiveState
        anchors.centerIn: parent
        spacing: 3
        Rectangle { width: 3; height: 11; radius: 1; color: root.fgTint }
        Rectangle { width: 3; height: 11; radius: 1; color: root.fgTint }
    }

    // Iconos Play y Altavoz/Mute
    Canvas {
        visible: root.iconType === "mute" || (root.iconType === "play" && !root.isActiveState)
        anchors.centerIn: parent
        width: 16
        height: 16

        property color tint: root.fgTint
        property bool flag: root.isActiveState
        onTintChanged: requestPaint()
        onFlagChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = tint;
            ctx.strokeStyle = tint;
            ctx.lineWidth = 1.6;
            ctx.lineCap = "round";

            if (root.iconType === "play") {
                ctx.beginPath();
                ctx.moveTo(4, 2.5);
                ctx.lineTo(13, 8);
                ctx.lineTo(4, 13.5);
                ctx.closePath();
                ctx.fill();
            } else {
                ctx.beginPath();
                ctx.moveTo(2, 6); ctx.lineTo(5, 6); ctx.lineTo(9, 2.5);
                ctx.lineTo(9, 13.5); ctx.lineTo(5, 10); ctx.lineTo(2, 10);
                ctx.closePath();
                ctx.fill();

                if (flag) {
                    ctx.beginPath();
                    ctx.moveTo(11.5, 5.5); ctx.lineTo(15, 10.5);
                    ctx.moveTo(15, 5.5); ctx.lineTo(11.5, 10.5);
                    ctx.stroke();
                } else {
                    ctx.beginPath();
                    ctx.arc(9.5, 8, 3.2, -Math.PI * 0.35, Math.PI * 0.35);
                    ctx.stroke();
                }
            }
        }
    }

    MouseArea {
        id: btnArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
