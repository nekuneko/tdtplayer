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
    
    visible: root.sidebarForceOpen
    width: visible ? 260 : 0
    hoverEnabled: true

    onExited: {
        root.sidebarForceOpen = false
        root.mouseExitedSidebar() 
        
        if (typeof globalKeyboardHandler !== "undefined") {
            globalKeyboardHandler.forceActiveFocus();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#0F172A" 
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
                    color: "#94A3B8" 
                    font.pointSize: 11
                }
            }
        }

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

        // 🪓 El muelle elástico: empuja de forma estricta todo lo que esté debajo al fondo
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
        }

        // 🚀 NUEVO BOTÓN: Salida nativa abajo del todo
        ItemDelegate {
            id: quitOpt
            Layout.fillWidth: true
            height: 50
            hoverEnabled: true

            background: Rectangle {
                // Cambia a rojo sutil al pasar el cursor por encima
                color: quitOpt.hovered ? "#EF4444" : "transparent"
                radius: 8
                opacity: quitOpt.hovered ? 0.2 : 1.0
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            contentItem: RowLayout {
                spacing: 12
                Text { 
                    text: "🚪"
                    font.pointSize: 14 
                    // Si está en hover se mantiene blanco, si no, adopta el color rojo corporativo de aviso
                    color: quitOpt.hovered ? "#FFFFFF" : "#EF4444"
                }
                Text {
                    text: "Salir de la Aplicación"
                    color: quitOpt.hovered ? "#FFFFFF" : "#EF4444"
                    font.bold: true
                    font.pointSize: 11
                }
            }

            onClicked: {
                // Invoca la directiva de destrucción del hilo del motor de PySide6/Qt6
                Qt.quit()
            }
        }
    }
}
