// qml/EpgDrawer.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    
    // Propiedades públicas de la interfaz del componente
    property string channelName: ""
    property string channelNo: ""
    property string hoveredChannelName: ""
    property string channelLogo: "" 
    property string epgTitle: ""
    property string epgDescription: ""
    property bool isFullScreen: false
    property var sidebarItem: null
    property bool epgForceOpen: false

    height: root.isFullScreen ? 180 : 160 
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.left: parent ? parent.left : undefined
    
    color: "#0F172A" 
    opacity: 0.96
    border.color: "#3B82F6"
    border.width: root.isFullScreen ? 1 : 0

    Behavior on height {
        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
    }

    // Detector de presencia del cursor sobre el área del panel
    MouseArea {
        id: epgMouseTracker
        anchors.fill: parent
        hoverEnabled: true
        z: -1 
        onExited: root.epgForceOpen = false
    }

    // Contenedor estructural principal
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // Submódulo 1: Cabecera del canal sin el reloj secundario
        EpgHeaderRow {
            isFullScreen: root.isFullScreen
            channelNo: root.channelNo
            channelName: root.channelName
            hoveredChannelName: root.hoveredChannelName
        }

        // Línea divisoria decorativa
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#334155"
        }

        // Submódulo 2: Bloque de información del contenido actual (Logo + Guía)
        EpgProgramContent {
            isFullScreen: root.isFullScreen
            channelLogo: root.channelLogo
            epgTitle: root.epgTitle
            epgDescription: root.epgDescription
        }
    }

    // Capturador de la rueda para ajuste de volumen directo sobre el EPG
    WheelHandler {
        id: drawerVolumeWheel
        orientation: Qt.Vertical
        onWheel: (event) => {
            if (event.angleDelta.y > 0) {
                ctrl.changeVolume(5)
            } else if (event.angleDelta.y < 0) {
                ctrl.changeVolume(-5)
            }
        }
    }

    // ===================================================================
    // 🧱 SUB-COMPONENTES INTERNOS (MODULARIZACIÓN)
    // ===================================================================

    component EpgHeaderRow : RowLayout {
        required property bool isFullScreen
        required property string channelNo
        required property string channelName
        required property string hoveredChannelName

        Layout.fillWidth: true
        spacing: 12

        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignLeft

            Rectangle {
                visible: channelNo !== ""
                color: "#3B82F6"
                radius: 4
                Layout.preferredWidth: 42
                Layout.preferredHeight: 22
                
                Text {
                    anchors.centerIn: parent
                    text: channelNo.padStart(2, '0')
                    color: "white"
                    font.bold: true
                    font.pointSize: 10
                }
            }

            Text {
                text: hoveredChannelName !== "" ? hoveredChannelName : channelName
                color: "white"
                font.bold: true
                font.pointSize: isFullScreen ? 14 : 12
                elide: Text.ElideRight
            }
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            spacing: 12
            Layout.alignment: Qt.AlignRight

            // Indicador de transmisión en vivo
            Rectangle {
                color: "#EF4444" 
                radius: 4
                Layout.preferredHeight: 22
                Layout.preferredWidth: liveLabelLayout.implicitWidth + 16 

                RowLayout {
                    id: liveLabelLayout
                    anchors.centerIn: parent
                    spacing: 6
                    Rectangle { width: 6; height: 6; radius: 3; color: "white"; Layout.alignment: Qt.AlignVCenter }
                    Text { text: "EN DIRECTO AHORA"; color: "white"; font.bold: true; font.pointSize: 8; Layout.alignment: Qt.AlignVCenter }
                }
            }
        }
    }

    component EpgProgramContent : RowLayout {
        required property bool isFullScreen
        required property string channelLogo
        required property string epgTitle
        required property string epgDescription

        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        // 🛡️ ESCUDO DE EVENTOS: Absorbe todos los scrolls verticales para evitar zapping accidental
        WheelHandler {
            id: contentScrollShield
            orientation: Qt.Vertical
            onWheel: (event) => {
                if (descFlickable.visible) {
                    if (event.angleDelta.y > 0) {
                        descFlickable.contentY = Math.max(0, descFlickable.contentY - 25)
                    } else {
                        descFlickable.contentY = Math.min(descFlickable.contentHeight - descFlickable.height, descFlickable.contentY + 25)
                    }
                }
                event.accepted = true
            }
        }

        // Contenedor del logotipo
        Rectangle {
            Layout.preferredWidth: 60
            Layout.preferredHeight: 60
            color: "#1E293B"
            radius: 8
            Layout.alignment: Qt.AlignTop

            Image {
                anchors.fill: parent
                anchors.margins: 4
                source: channelLogo
                fillMode: Image.PreserveAspectFit
                onStatusChanged: if (status === Image.Error || channelLogo === "") source = "image://theme/media-playback-start"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            // Propiedades analíticas locales para extraer las horas limpias sin corchetes
            readonly property var timeMatch: epgTitle.match(/^\[(\d{2}:\d{2}\s*-\s*\d{2}:\d{2})\]\s*(.*)$/)
            readonly property bool hasTime: timeMatch !== null
            readonly property string extractedTime: hasTime ? timeMatch[1].trim() : ""
            readonly property string cleanTitle: hasTime ? timeMatch[2].trim() : epgTitle

            // 🕒 Bloque de Horarios Superior Estilizado
            RowLayout {
                visible: parent.hasTime
                spacing: 6
                Layout.fillWidth: true

                Text {
                    text: "🕒"
                    font.pointSize: isFullScreen ? 10 : 9
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: parent.parent.extractedTime
                    color: "#94A3B8" 
                    font.bold: true
                    font.pointSize: isFullScreen ? 11 : 10
                    font.family: "Monospace"
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Título Principal del Programa
            Text {
                text: parent.cleanTitle
                color: "#FFFFFF" 
                font.bold: true
                font.pointSize: isFullScreen ? 15 : 13
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // Espaciador mínimo antes de la sinopsis
            Item { Layout.preferredHeight: 2 }

            // Área scrolleable de la sinopsis o descripción
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Flickable {
                    id: descFlickable
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: descriptionText.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Text {
                        id: descriptionText
                        width: descFlickable.width
                        text: epgDescription
                        color: "#64748B" 
                        font.pointSize: isFullScreen ? 11 : 10
                        wrapMode: Text.WordWrap
                    }

                    ScrollBar.vertical: ScrollBar {
                        id: verticalScrollBar
                        policy: descFlickable.contentHeight > descFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                        
                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            color: "#475569"
                        }
                    }
                }
            }
        }
    }
}
