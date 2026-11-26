// qml/EpgVolumeSlider.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    spacing: 8
    Layout.alignment: Qt.AlignVCenter

    readonly property bool isMutedVisual: typeof ctrl !== "undefined" && (ctrl.isMuted || ctrl.currentVolumePercent === 0)
    readonly property color alertBg: appTheme.liveBg
    readonly property color alertFg: appTheme.liveText

    Rectangle {
        id: muteBtn
        width: 32
        height: 32
        radius: appTheme.px(8)
        Layout.alignment: Qt.AlignVCenter

        color: root.isMutedVisual
               ? root.alertBg
               : (muteArea.containsMouse ? appTheme.bgItemActive : appTheme.bgItemDefault)
        border.color: root.isMutedVisual
                      ? root.alertBg
                      : (muteArea.containsMouse ? appTheme.borderActive : appTheme.borderDefault)
        border.width: 1

        Canvas {
            anchors.centerIn: parent
            width: 16
            height: 16

            property color tint: root.isMutedVisual
                                 ? root.alertFg
                                 : (muteArea.containsMouse ? appTheme.textTitleActive : appTheme.textTitle)
            property bool flag: root.isMutedVisual
            onTintChanged: requestPaint()
            onFlagChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = tint;
                ctx.strokeStyle = tint;
                ctx.lineWidth = 1.6;
                ctx.lineCap = "round";

                ctx.beginPath();
                ctx.moveTo(2, 6);
                ctx.lineTo(5, 6);
                ctx.lineTo(9, 2.5);
                ctx.lineTo(9, 13.5);
                ctx.lineTo(5, 10);
                ctx.lineTo(2, 10);
                ctx.closePath();
                ctx.fill();

                if (flag) {
                    ctx.beginPath();
                    ctx.moveTo(11.5, 5.5);
                    ctx.lineTo(15, 10.5);
                    ctx.moveTo(15, 5.5);
                    ctx.lineTo(11.5, 10.5);
                    ctx.stroke();
                } else {
                    ctx.beginPath();
                    ctx.arc(9.5, 8, 3.2, -Math.PI * 0.35, Math.PI * 0.35);
                    ctx.stroke();
                }
            }
        }

        MouseArea {
            id: muteArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => mouse.accepted = true
            onClicked: {
                if (typeof ctrl !== "undefined") {
                    ctrl.toggleMute();
                }
            }
        }
    }

    Slider {
        id: volumeSlider
        from: 0
        to: 100
        value: root.isMutedVisual ? 0 : ctrl.currentVolumePercent
        Layout.preferredWidth: 100
        Layout.preferredHeight: 20
        Layout.alignment: Qt.AlignVCenter

        onMoved: {
            var diff = Math.round(value) - ctrl.currentVolumePercent;
            ctrl.changeVolume(diff);
        }

        background: Rectangle {
            x: volumeSlider.leftPadding
            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
            implicitWidth: 100
            implicitHeight: 4
            width: volumeSlider.availableWidth
            height: implicitHeight
            radius: 2
            color: appTheme.borderDefault

            Rectangle {
                width: volumeSlider.visualPosition * parent.width
                height: parent.height
                color: root.isMutedVisual ? "#64748B" : appTheme.borderActive
                radius: 2
            }
        }

        handle: Rectangle {
            x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
            implicitWidth: 12
            implicitHeight: 12
            radius: 6
            color: root.isMutedVisual ? "#475569" : appTheme.borderActive
            border.color: "#FFFFFF"
            border.width: 1
        }
    }

    Text {
        text: (root.isMutedVisual ? "0" : ctrl.currentVolumePercent) + "%"
        color: root.isMutedVisual ? root.alertBg : appTheme.textDesc
        font.bold: true
        font.pointSize: 9
        font.family: "Monospace"
        Layout.preferredWidth: 32
        Layout.alignment: Qt.AlignVCenter
        renderType: Text.NativeRendering
    }
}
