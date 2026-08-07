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
    width: visible ? 260 : 0
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
        // 🚀 ENLACE DE PALETA: Fondo adaptado de manera armoniosa al perfil activo
        color: appTheme.bgItemDefault
        border.color: appTheme.borderDefault
        border.width: root.isFullScreen ? 1 : 0
    }

    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Text {
            text: "CONFIGURACIÓN"
            color: appTheme.textDesc
            font.bold: true
            font.pointSize: 10
            Layout.bottomMargin: 5
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Layout.preferredHeight: 180

            Text {
                text: "Seleccionar Tema Visual"
                color: appTheme.textDesc
                font.bold: true
                font.pointSize: 10
                Layout.bottomMargin: 4
            }

            ListView {
                id: themeVerticalList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.appThemeItem ? root.appThemeItem.themeKeys : []
                clip: true
                spacing: 4

                delegate: ItemDelegate {
                    id: themeBtnDelegate
                    width: themeVerticalList.width
                    height: 32
                    hoverEnabled: true

                    readonly property string themeKey: modelData
                    readonly property bool isSelected: root.appThemeItem && root.appThemeItem.currentTheme === themeBtnDelegate.themeKey

                    background: Rectangle {
                        color: themeBtnDelegate.isSelected 
                               ? appTheme.bgItemActive 
                               : (themeBtnDelegate.hovered ? appTheme.bgItemHover : appTheme.badgeTimeBg)
                        radius: 4
                        border.color: themeBtnDelegate.isSelected ? appTheme.borderActive : "transparent"
                        border.width: 1
                    }

                    contentItem: Text {
                        text: (root.appThemeItem && root.appThemeItem.colors[themeBtnDelegate.themeKey])
                              ? root.appThemeItem.colors[themeBtnDelegate.themeKey]["name"]
                              : themeBtnDelegate.themeKey
                        color: themeBtnDelegate.isSelected ? appTheme.textTitleActive : appTheme.textTitle
                        font.bold: themeBtnDelegate.isSelected
                        font.pointSize: 10
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 8
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

        ItemDelegate {
            id: generalOpt
            Layout.fillWidth: true
            height: 50
            hoverEnabled: true
            background: Rectangle { color: generalOpt.hovered ? appTheme.bgItemHover : "transparent"; radius: 8 }
            contentItem: RowLayout { 
                spacing: 12 
                Text { text: "⚙️"; font.pointSize: 14 } 
                Text { text: "Configuración General"; color: appTheme.textDesc; font.pointSize: 11 } 
            }
        }

        ItemDelegate {
            id: importOpt
            Layout.fillWidth: true
            height: 50
            hoverEnabled: true
            background: Rectangle { color: importOpt.hovered ? appTheme.bgItemActive : "transparent"; radius: 8; opacity: importOpt.hovered ? 0.4 : 1.0 }
            contentItem: RowLayout { 
                spacing: 12 
                Text { text: "➕"; font.pointSize: 14 } 
                Text { text: "Importar Lista M3U"; color: appTheme.textTitle; font.bold: true; font.pointSize: 11 } 
            }
            onClicked: { root.importRequested(); if (root.isFullScreen) { root.sidebarForceOpen = false } }
        }

        Item { Layout.fillHeight: true; Layout.fillWidth: true }

        ItemDelegate {
            id: quitOpt
            Layout.fillWidth: true
            height: 50
            hoverEnabled: true
            background: Rectangle { color: quitOpt.hovered ? "#EF4444" : "transparent"; radius: 8; opacity: quitOpt.hovered ? 0.2 : 1.0 }
            contentItem: RowLayout { 
                spacing: 12 
                Text { text: "🚪"; font.pointSize: 14; color: quitOpt.hovered ? "#FFFFFF" : "#EF4444" } 
                Text { text: "Salir de la Aplicación"; color: quitOpt.hovered ? "#FFFFFF" : "#EF4444"; font.bold: true; font.pointSize: 11 } 
            }
            onClicked: Qt.quit()
        }
    }
}
