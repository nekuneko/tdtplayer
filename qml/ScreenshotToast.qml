// qml/ScreenshotToast.qml
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string messageText: ""
    property bool isError: false

    anchors.top: parent ? parent.top : undefined
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    anchors.topMargin: (typeof appTheme !== "undefined" && appTheme) ? appTheme.px(20) : 20

    width: Math.min(parent ? parent.width - 32 : 360, toastLayout.implicitWidth + ((typeof appTheme !== "undefined" && appTheme) ? appTheme.px(28) : 28))
    height: (typeof appTheme !== "undefined" && appTheme) ? appTheme.px(38) : 38
    radius: (typeof appTheme !== "undefined" && appTheme) ? appTheme.px(12) : 12

    color: (typeof appTheme !== "undefined" && appTheme) ? appTheme.bgAbsolute : "#0B0F17"
    border.color: root.isError
                  ? ((typeof appTheme !== "undefined" && appTheme) ? appTheme.liveBg : "#EF4444")
                  : ((typeof appTheme !== "undefined" && appTheme) ? appTheme.borderActive : "#60A5FA")
    border.width: 1.5

    opacity: 0.0
    visible: opacity > 0.01

    Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    function showToast(text, errorState) {
        root.messageText = text;
        root.isError = Boolean(errorState);
        root.opacity = 1.0;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1800
        repeat: false
        onTriggered: root.opacity = 0.0
    }

    Connections {
        target: typeof screenshotHelper !== "undefined" ? screenshotHelper : null
        function onScreenshotSaved(filePath) {
            var fileName = filePath.split(/[\\/]/).pop();
            root.showToast("Captura guardada: " + fileName, false);
        }
        function onScreenshotFailed(reason) {
            root.showToast(reason, true);
        }
    }

    RowLayout {
        id: toastLayout
        anchors.centerIn: parent
        width: Math.min(root.width - 20, implicitWidth)
        spacing: 8

        Rectangle {
            Layout.preferredWidth: 8
            Layout.preferredHeight: 8
            radius: 4
            color: root.isError
                   ? ((typeof appTheme !== "undefined" && appTheme) ? appTheme.liveBg : "#EF4444")
                   : ((typeof appTheme !== "undefined" && appTheme) ? appTheme.borderActive : "#60A5FA")
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.messageText
            color: (typeof appTheme !== "undefined" && appTheme) ? appTheme.textTitle : "#FFFFFF"
            font.bold: true
            font.pointSize: (typeof appTheme !== "undefined" && appTheme) ? appTheme.pt(9.5) : 9.5
            elide: Text.ElideMiddle
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            renderType: Text.NativeRendering
        }
    }
}
