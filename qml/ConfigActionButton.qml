// qml/ConfigActionButton.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    id: root

    required property string labelText
    required property string iconType // "camera" | "import" | "power"
    required property var appThemeItem
    property bool isDanger: false

    Layout.fillWidth: true
    Layout.preferredHeight: root.appThemeItem ? root.appThemeItem.px(40) : 40
    hoverEnabled: true

    readonly property color activeBg: root.isDanger ? appTheme.liveBg : appTheme.bgItemActive
    readonly property color fgColor: root.hovered
                                     ? (root.isDanger ? appTheme.liveText : appTheme.textTitleActive)
                                     : (root.isDanger ? appTheme.liveBg : appTheme.textTitle)
    readonly property color iconTint: root.hovered
                                      ? fgColor
                                      : (root.isDanger ? appTheme.liveBg : appTheme.borderActive)

    background: Rectangle {
        color: root.hovered ? root.activeBg : appTheme.bgItemDefault
        radius: root.appThemeItem ? root.appThemeItem.px(10) : 10
        border.color: root.hovered ? root.activeBg : appTheme.borderDefault
        border.width: 1
    }

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.appThemeItem ? root.appThemeItem.px(12) : 12
        anchors.rightMargin: root.appThemeItem ? root.appThemeItem.px(12) : 12
        spacing: root.appThemeItem ? root.appThemeItem.px(10) : 10

        // Icono vectorial "+"
        Item {
            visible: root.iconType === "import"
            Layout.preferredWidth: root.appThemeItem ? root.appThemeItem.px(15) : 15
            Layout.preferredHeight: root.appThemeItem ? root.appThemeItem.px(15) : 15
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.8
                height: 2
                radius: 1
                color: root.iconTint
            }
            Rectangle {
                anchors.centerIn: parent
                width: 2
                height: parent.height * 0.8
                radius: 1
                color: root.iconTint
            }
        }

        // Iconos vectoriales Cámara y Power
        Canvas {
            visible: root.iconType === "power" || root.iconType === "camera"
            Layout.preferredWidth: root.appThemeItem ? root.appThemeItem.px(16) : 16
            Layout.preferredHeight: root.appThemeItem ? root.appThemeItem.px(16) : 16
            Layout.alignment: Qt.AlignVCenter

            property color strokeColor: root.iconTint
            onStrokeColorChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.strokeStyle = strokeColor;
                ctx.lineWidth = 1.8;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";

                if (root.iconType === "camera") {
                    ctx.beginPath();
                    ctx.roundedRect(1.5, 4.5, width - 3, height - 6.5, 2.5, 2.5);
                    ctx.stroke();
                    ctx.beginPath();
                    ctx.moveTo(5.2, 4.5);
                    ctx.lineTo(6.4, 2.5);
                    ctx.lineTo(width - 6.4, 2.5);
                    ctx.lineTo(width - 5.2, 4.5);
                    ctx.stroke();
                    ctx.beginPath();
                    ctx.arc(width / 2, (height + 2.5) / 2, 2.6, 0, Math.PI * 2);
                    ctx.stroke();
                } else {
                    var cx = width / 2;
                    var cy = height / 2;
                    var r = Math.min(width, height) * 0.36;
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, -Math.PI * 0.25, Math.PI * 1.25, false);
                    ctx.stroke();
                    ctx.beginPath();
                    ctx.moveTo(cx, cy - r * 1.15);
                    ctx.lineTo(cx, cy);
                    ctx.stroke();
                }
            }
        }

        Text {
            text: root.labelText
            color: root.fgColor
            font.bold: true
            font.pointSize: root.appThemeItem ? root.appThemeItem.pt(9.5) : 9.5
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            renderType: Text.NativeRendering
        }
    }
}
