// qml/ConfigSidebar.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

MouseArea {
    id: root
    property bool isFullScreen: false
    property bool sidebarForceOpen: false

    signal importRequested()
    signal mouseExitedSidebar()

    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    
    // 🛠️ REPARADO: Ya no depende del modo ventana. Solo es visible si se fuerza su apertura con el ratón
    visible: root.sidebarForceOpen
    width: visible ? 260 : 0
    hoverEnabled: true

    // 🛠️ REPARADO: Comportamiento idéntico al drawer derecho al abandonar el ratón
    onExited: {
        root.sidebarForceOpen = false
        root.mouseExitedSidebar() // Despierta la restauración en main.qml
        
        if (typeof globalKeyboardHandler !== "undefined") {
            globalKeyboardHandler.forceActiveFocus();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#0F172A" // Slate 900
        border.color: "#3B82F6"
        border.width: root.isFullScreen ? 1 : 0
    }

    Behavior on width {
        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Text {
            text: "CONFIGURACIÓN"
            color: "#64748B"
            font.bold: true
            font.pointSize: 10
            Layout.bottomMargin: 10
        }

        // Opción 1: Configuración General (Vacía)
        ItemDelegate {
            id: generalOpt
            Layout.fillWidth: true
            height: 50
            hoverEnabled: true

            background: Rectangle {
                color: generalOpt.hovered ? "#1E293B" : "transparent"
                radius: 8
            }

            contentItem: RowLayout {
                spacing: 12
                Text { text: "⚙️"; font.pointSize: 14 }
                Text {
                    text: "Configuración General"
                    color: "#94A3B8" // Color atenuado al estar vacío
                    font.pointSize: 11
                }
            }
        }

        // Opción 2: Importar Lista M3U
        ItemDelegate {
            id: importOpt
            Layout.fillWidth: true
            height: 50
            hoverEnabled: true

            background: Rectangle {
                color: importOpt.hovered ? "#1E3A8A" : "transparent"
                radius: 8
                opacity: importOpt.hovered ? 0.4 : 1.0
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            contentItem: RowLayout {
                spacing: 12
                Text { text: "➕"; font.pointSize: 14 }
                Text {
                    text: "Importar Lista M3U"
                    color: "white"
                    font.bold: true
                    font.pointSize: 11
                }
            }

            onClicked: {
                root.importRequested();
                if (root.isFullScreen) {
                    root.sidebarForceOpen = false;
                }
            }
        }

        // Espaciador para empujar el contenido hacia arriba
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }
}
