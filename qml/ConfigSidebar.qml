// qml/ConfigSidebar.qml
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool isFullScreen: false
    property bool sidebarForceOpen: false

    property var appSettingsItem: null
    property var appThemeItem: null

    signal importRequested()
    signal mouseExitedSidebar()

    function px(v) { return root.appThemeItem ? root.appThemeItem.px(v) : v; }
    function pt(v) { return root.appThemeItem ? root.appThemeItem.pt(v) : v; }

    function closeSidebar(notifyExit) {
        root.sidebarForceOpen = false;
        if (notifyExit) {
            root.mouseExitedSidebar();
        }
        if (typeof globalKeyboardHandler !== "undefined") {
            globalKeyboardHandler.forceActiveFocus();
        }
    }

    readonly property real outerMargin: px(12)

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    visible: root.sidebarForceOpen
    width: (parent ? Math.min(px(245), Math.max(px(185), parent.width * 0.40)) : px(245)) + outerMargin
    hoverEnabled: true

    x: root.sidebarForceOpen ? 0 : -width

    Behavior on x {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    onExited: root.closeSidebar(true)

    Rectangle {
        anchors.fill: parent
        anchors.margins: root.outerMargin
        color: root.appThemeItem.bgAbsolute
        radius: root.px(16)
        border.color: root.appThemeItem.borderDefault
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.outerMargin + root.px(14)
        spacing: root.px(12)

        Text {
            text: "CONFIGURACIÓN"
            color: root.appThemeItem.textTitle
            font.bold: true
            font.letterSpacing: 1.4
            font.pointSize: root.pt(10.5)
            renderType: Text.NativeRendering
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.appThemeItem.borderDefault
        }

        Text {
            text: "Tema Visual"
            color: root.appThemeItem.textDesc
            font.bold: true
            font.pointSize: root.pt(9)
            renderType: Text.NativeRendering
        }

        ConfigThemeList {
            appThemeItem: root.appThemeItem
            appSettingsItem: root.appSettingsItem
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.appThemeItem.borderDefault
        }

        ConfigActionButton {
            labelText: "Capturar Pantalla (S)"
            iconType: "camera"
            appThemeItem: root.appThemeItem
            onClicked: {
                if (typeof screenshotHelper !== "undefined") {
                    screenshotHelper.capture_frame(typeof ctrl !== "undefined" ? ctrl.osdChannelName : "");
                }
                root.closeSidebar(false);
            }
        }

        ConfigActionButton {
            labelText: "Importar Lista M3U"
            iconType: "import"
            appThemeItem: root.appThemeItem
            onClicked: {
                root.importRequested();
                root.closeSidebar(false);
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
        onWheel: event => event.accepted = true
    }
}
