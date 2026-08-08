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

    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    
    visible: root.sidebarForceOpen
    width: root.appThemeItem ? root.appThemeItem.px(260) : 260
    hoverEnabled: true

    onExited: {
        root.sidebarForceOpen = false
        root.mouseExitedSidebar() 
        if (typeof globalKeyboardHandler !== "undefined") {
            globalKeyboardHandler.forceActiveFocus()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: appTheme ? appTheme.bgAbsolute : "#0F172A"
        border.color: appTheme ? appTheme.borderDefault : "#334155"
        border.width: root.isFullScreen ? 1 : 0
    }

    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.appThemeItem ? root.appThemeItem.px(20) : 20
        spacing: root.appThemeItem ? root.appThemeItem.px(15) : 15

        Text {
            text: "CONFIGURACIÓN"
            color: appTheme ? appTheme.textDesc : "#64748B"
            font.bold: true
            font.pointSize: root.appThemeItem ? root.appThemeItem.pt(10) : 10
            Layout.bottomMargin: root.appThemeItem ? root.appThemeItem.px(5) : 5
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: root.appThemeItem ? root.appThemeItem.px(6) : 6
            Layout.preferredHeight: root.appThemeItem ? root.appThemeItem.px(180) : 180

            Text {
                text: "Seleccionar Tema Visual"
                color: appTheme ? appTheme.textDesc : "#94A3B8"
                font.bold: true
                font.pointSize: root.appThemeItem ? root.appThemeItem.pt(10) : 10
                Layout.bottomMargin: root.appThemeItem ? root.appThemeItem.px(4) : 4
            }

            ListView {
                id: themeVerticalList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.appThemeItem ? root.appThemeItem.themeKeys : []
                clip: true
                spacing: root.appThemeItem ? root.appThemeItem.px(4) : 4

                delegate: ItemDelegate {
                    id: themeBtnDelegate
                    width: themeVerticalList.width
                    height: root.appThemeItem ? root.appThemeItem.px(32) : 32
                    hoverEnabled: true

                    readonly property string themeKey: modelData
                    readonly property bool isSelected: root.appThemeItem && root.appThemeItem.currentTheme === themeBtnDelegate.themeKey

                    background: Rectangle {
                        color: themeBtnDelegate.isSelected ? appTheme.bgItemActive : (themeBtnDelegate.hovered ? appTheme.bgItemHover : appTheme.badgeTimeBg)
                        radius: 4
                        border.color: themeBtnDelegate.isSelected ? appTheme.borderActive : "transparent"
                        border.width: 1
                    }

                    contentItem: Text {
                        text: (root.appThemeItem && root.appThemeItem.colors[themeBtnDelegate.themeKey]) ? root.appThemeItem.colors[themeBtnDelegate.themeKey]["name"] : themeBtnDelegate.themeKey
                        color: themeBtnDelegate.isSelected ? appTheme.textTitleActive : appTheme.textTitle
                        font.bold: themeBtnDelegate.isSelected
                        font.pointSize: root.appThemeItem ? root.appThemeItem.pt(10) : 10
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: root.appThemeItem ? root.appThemeItem.px(8) : 8
                    }

                    onClicked: {
                        if (root.appThemeItem && root.appSettingsItem) {
                            root.appThemeItem.currentTheme = themeBtnDelegate.themeKey
                            root.appSettingsItem.lastTheme = themeBtnDelegate.themeKey
                        }
                    }
                }
            }
        }

        // 🚀 RESTRUCTURACIÓN LIMPIA: Separación estricta por saltos de línea normativos de Qt6
        ItemDelegate {
            id: generalOpt
            Layout.fillWidth: true
            height: root.appThemeItem ? root.appThemeItem.px(50) : 50
            hoverEnabled: true
            background: Rectangle { color: generalOpt.hovered ? appTheme.bgItemHover : "transparent"; radius: 8 }
            contentItem: RowLayout { 
                spacing: root.appThemeItem ? root.appThemeItem.px(12) : 12
                Text { 
                    text: "⚙️"
                    font.pointSize: root.appThemeItem ? root.appThemeItem.pt(14) : 14 
                }
                Text { 
                    text: "Configuración General"
                    color: appTheme.textDesc
                    font.pointSize: root.appThemeItem ? root.appThemeItem.pt(11) : 11 
                }
            }
        }

        ItemDelegate {
            id: importOpt
            Layout.fillWidth: true
            height: root.appThemeItem ? root.appThemeItem.px(50) : 50
            hoverEnabled: true
            background: Rectangle { color: importOpt.hovered ? appTheme.bgItemActive : "transparent"; radius: 8; opacity: importOpt.hovered ? 0.4 : 1.0 }
            contentItem: RowLayout { 
                spacing: root.appThemeItem ? root.appThemeItem.px(12) : 12
                Text { 
                    text: "➕"
                    font.pointSize: root.appThemeItem ? root.appThemeItem.pt(14) : 14 
                }
                Text { 
                    text: "Importar Lista M3U"
                    color: appTheme.textTitle
                    font.bold: true
                    font.pointSize: root.appThemeItem ? root.appThemeItem.pt(11) : 11 
                }
            }
            onClicked: { root.importRequested(); if (root.isFullScreen) root.sidebarForceOpen = false }
        }

        Item { Layout.fillHeight: true; Layout.fillWidth: true }

        ItemDelegate {
            id: quitOpt
            Layout.fillWidth: true
            height: root.appThemeItem ? root.appThemeItem.px(50) : 50
            hoverEnabled: true
            background: Rectangle { color: quitOpt.hovered ? "#EF4444" : "transparent"; radius: 8; opacity: quitOpt.hovered ? 0.2 : 1.0 }
            contentItem: RowLayout { 
                spacing: root.appThemeItem ? root.appThemeItem.px(12) : 12
                Text { 
                    text: "🚪"
                    font.pointSize: root.appThemeItem ? root.appThemeItem.pt(14) : 14
                    color: quitOpt.hovered ? "#FFFFFF" : "#EF4444" 
                }
                Text { 
                    text: "Salir de la Aplicación"
                    color: quitOpt.hovered ? "#FFFFFF" : "#EF4444"
                    font.bold: true
                    font.pointSize: root.appThemeItem ? root.appThemeItem.pt(11) : 11 
                }
            }
            onClicked: Qt.quit()
        }
    }
}
