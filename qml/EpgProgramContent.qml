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

                // Buscamos el cierre del corchete ']' que inyecta Python para recortar las cadenas limpiamente
                readonly property int closeBracketIndex: root.epgTitle.indexOf("]")
                readonly property bool hasTime: root.epgTitle.startsWith("[") && closeBracketIndex !== -1
                
                // 🚀 LIMPIEZA TOTAL: Recortamos omitiendo los corchetes exteriores [ ]
                readonly property string extractedTime: hasTime ? root.epgTitle.substring(1, closeBracketIndex).trim() : ""
                readonly property string cleanTitle: hasTime ? root.epgTitle.substring(closeBracketIndex + 1).trim() : root.epgTitle

                // Bloque 1: Horario Estilizado Limpio con Icono
                RowLayout {
                    visible: scrollContentLayout.hasTime
                    spacing: 6
                    Layout.fillWidth: true

                    Text { text: "🕒"; font.pointSize: root.isFullScreen ? 10 : 9; Layout.alignment: Qt.AlignVCenter }

                    Text {
                        text: scrollContentLayout.extractedTime
                        color: "#E2E8F0" 
                        font.bold: true
                        font.pointSize: root.isFullScreen ? 11 : 10
                        font.family: "Monospace"
                        renderType: Text.NativeRendering
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                // Bloque 2: Título Principal del Programa
                Text {
                    text: scrollContentLayout.cleanTitle
                    color: "#FFFFFF" 
                    font.bold: true
                    font.pointSize: root.isFullScreen ? 15 : 13
                    renderType: Text.NativeRendering
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap 
                }

                Item { Layout.preferredHeight: 2 }

                // Bloque 3: Cuerpo de la Sinopsis en alto contraste legible
                Text {
                    id: descriptionText
                    Layout.fillWidth: true
                    text: root.epgDescription
                    color: "#CBD5E1" 
                    font.pointSize: root.isFullScreen ? 11 : 10
                    renderType: Text.NativeRendering
                    wrapMode: Text.WordWrap
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: descFlickable.contentHeight > descFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#FFFFFF" } 
            }
        }
    }
}
