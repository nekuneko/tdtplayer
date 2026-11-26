// qml/ConfigSidebar.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

MouseArea {
    id: root
    property bool isFullScreen: false
    property bool sidebarForceOpen: false

    property var appSettingsItem: null
    property var appThemeItem: null

    signal importRequested()
    signal mouseExitedSidebar()

    readonly property real outerMargin: root.appThemeItem ? root.appThemeItem.px(12) : 12

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    visible: root.sidebarForceOpen
    width: (parent
           ? Math.min(root.appThemeItem ? root.appThemeItem.px(245) : 245, Math.max(root.appThemeItem ? root.appThemeItem.px(185) : 185, parent.width * 0.40))
           : (root.appThemeItem ? root.appThemeItem.px(245) : 245)) + outerMargin
    hoverEnabled: true

    x: root.sidebarForceOpen ? 0 : -width

    Behavior on x {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    onExited: {
        root.sidebarForceOpen = false;
        root.mouseExitedSidebar();
        if (typeof globalKeyboardHandler !== "undefined") {
            globalKeyboardHandler.forceActiveFocus();
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: root.outerMargin
        color: appTheme ? appTheme.bgAbsolute : "#0B0F17"
        radius: root.appThemeItem ? root.appThemeItem.px(16) : 16
        border.color: appTheme ? appTheme.borderDefault : "#1E293B"
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.outerMargin + (root.appThemeItem ? root.appThemeItem.px(14) : 14)
        spacing: root.appThemeItem ? root.appThemeItem.px(12) : 12

        Text {
            text: "CONFIGURACIÓN"
            color: appTheme ? appTheme.textTitle : "#FFFFFF"
            font.bold: true
            font.letterSpacing: 1.4
            font.pointSize: root.appThemeItem ? root.appThemeItem.pt(10.5) : 10.5
            renderType: Text.NativeRendering
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: appTheme ? appTheme.borderDefault : "#1E293B"
        }

        Text {
            text: "Tema Visual"
            color: appTheme ? appTheme.textDesc : "#94A3B8"
            font.bold: true
            font.pointSize: root.appThemeItem ? root.appThemeItem.pt(9) : 9
            renderType: Text.NativeRendering
        }

        ConfigThemeList {
            appThemeItem: root.appThemeItem
            appSettingsItem: root.appSettingsItem
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: appTheme ? appTheme.borderDefault : "#1E293B"
        }

        ConfigActionButton {
            labelText: "Capturar Pantalla (S)"
            iconType: "camera"
            appThemeItem: root.appThemeItem
            onClicked: {
                if (typeof screenshotHelper !== "undefined") {
                    screenshotHelper.capture_frame(typeof ctrl !== "undefined" ? ctrl.osdChannelName : "");
                }
                root.sidebarForceOpen = false;
            }
        }

        ConfigActionButton {
            labelText: "Importar Lista M3U"
            iconType: "import"
            appThemeItem: root.appThemeItem
            onClicked: {
                root.importRequested();
                root.sidebarForceOpen = false;
            }
        }

        ConfigActionButton {
            labelText: "Salir de la Aplicación"
            iconType: "power"
            isDanger: true
            appThemeItem: root.appThemeItem
            onClicked: Qt.quit()
        }
    }

    WheelHandler {
        orientation: Qt.Vertical
        onWheel: event => {
            event.accepted = true;
        }
    }
}
