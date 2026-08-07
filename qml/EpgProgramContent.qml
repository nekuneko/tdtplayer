// qml/EpgProgramContent.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 20

    required property bool isFullScreen
    required property string channelLogo
    required property string epgTitle
    required property string epgDescription

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

    // Contenedor estático del Logotipo del canal sintonizado (Fijo a la izquierda)
    Rectangle {
        Layout.preferredWidth: 60
        Layout.preferredHeight: 60
        color: "#1E293B"
        radius: 8
        Layout.alignment: Qt.AlignTop

        Image {
            id: targetChannelLogoItem
            anchors.fill: parent
            anchors.margins: 4
            source: root.channelLogo
            fillMode: Image.PreserveAspectFit
            sourceSize.width: 120
            sourceSize.height: 120
            cache: true
            asynchronous: false

            onStatusChanged: {
                if (status === Image.Error || root.channelLogo === "") {
                    source = "image://theme/media-playback-start"
                }
            }
        }
    }

    // ÁREA SCROLLEABLE UNIFICADA (Hora + Título + Sinopsis)
    Item {
        id: scrollableWrapper
        Layout.fillWidth: true
        Layout.fillHeight: true
        
        Flickable {
            id: descFlickable
            anchors.fill: parent
            contentWidth: width
            contentHeight: scrollContentLayout.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: scrollContentLayout
                width: descFlickable.width
                spacing: 4

                // 🚀 CORRECCIÓN DE PARSEO SEGURA:
                // El índice [1] extrae directamente el texto capturado por los paréntesis (\\d{2}:\\d{2}\\s*-\\s*\\d{2}:\\d{2}) ya limpio de corchetes.
                readonly property var timeMatch: root.epgTitle.match(/^\[(\d{2}:\d{2}\s*-\s*\d{2}:\d{2})\]/)
                readonly property string extractedTime: timeMatch ? timeMatch[1] : ""
                readonly property string cleanTitle: timeMatch ? root.epgTitle.substring(timeMatch[0].length).trim() : root.epgTitle

                // 🕒 1. Bloque de Horarios Superior Estilizado con Icono (Ahora scrollea)
                RowLayout {
                    visible: scrollContentLayout.extractedTime !== ""
                    spacing: 6
                    Layout.fillWidth: true

                    Text {
                        text: "🕒"
                        font.pointSize: root.isFullScreen ? 10 : 9
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: scrollContentLayout.extractedTime
                        color: "#94A3B8" 
                        font.bold: true
                        font.pointSize: root.isFullScreen ? 11 : 10
                        font.family: "Monospace"
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                // 🚀 2. Título Principal del Programa en línea independiente (Debajo de la hora, ahora scrollea)
                Text {
                    text: scrollContentLayout.cleanTitle
                    color: "#FFFFFF" 
                    font.bold: true
                    font.pointSize: root.isFullScreen ? 15 : 13
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap 
                }

                // Espaciador mínimo antes de la sinopsis
                Item { Layout.preferredHeight: 2 }

                // 3. Área de la sinopsis o descripción del programa
                Text {
                    id: descriptionText
                    Layout.fillWidth: true
                    text: root.epgDescription
                    color: "#64748B" 
                    font.pointSize: root.isFullScreen ? 11 : 10
                    wrapMode: Text.WordWrap
                }
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
