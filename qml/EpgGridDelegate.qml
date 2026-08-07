// qml/EpgGridDelegate.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    id: root
    width: ListView.view.width
    height: 95 
    hoverEnabled: true
    
    // Propiedades requeridas por Qt6 desde el modelo
    required property int index
    required property string name
    required property string logo
    required property string chNo

    required property var channelModel
    required property int currentChannelIndex

    readonly property int itemIndex: root.index
    readonly property bool isCurrent: ListView.view.currentIndex === root.itemIndex || (root.currentChannelIndex === root.itemIndex && !ListView.view.activeFocus)

    background: Rectangle {
        color: root.isCurrent 
               ? "#1D4ED8" 
               : (root.hovered ? "#1E293B" : "#0B0F19") 
        opacity: root.isCurrent ? 0.7 : 0.9
        radius: 10
        border.color: root.isCurrent ? "#60A5FA" : (root.hovered ? "#64748B" : "#1E293B")
        border.width: root.isCurrent || root.hovered ? 1.5 : 1
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    // Limpieza de strings y procesamiento del EPG en caliente
    readonly property string channelNameStr: root.name ? root.name.toString().trim().replace(/[\r\n]/g, "") : ""
    readonly property var epgData: root.channelModel ? root.channelModel.fetch_current_epg(root.channelNameStr) : null
    readonly property string epgRawTitle: epgData ? epgData.title : "Emisión en directo"
    readonly property string epgDesc: epgData ? (epgData.description || "Sin descripción disponible.") : "..."

    readonly property int closeBracketIndex: root.epgRawTitle.indexOf("]")
    readonly property bool hasTime: root.epgRawTitle.startsWith("[") && root.closeBracketIndex !== -1
    
    readonly property string extractedTime: hasTime ? root.epgRawTitle.substring(0, root.closeBracketIndex + 1) : ""
    readonly property string cleanTitle: hasTime ? root.epgRawTitle.substring(root.closeBracketIndex + 1).trim() : root.epgRawTitle

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.margins: 16 
        spacing: 20

        // 1. Número de Canal con Badge Sólido
        Rectangle {
            color: root.isCurrent ? "#3B82F6" : "#334155" 
            radius: 6
            Layout.preferredWidth: 42
            Layout.preferredHeight: 28
            Layout.alignment: Qt.AlignVCenter
            
            Text {
                anchors.centerIn: parent
                text: root.chNo ? root.chNo.toString().padStart(2, '0') : root.itemIndex.toString().padStart(2, '0')
                color: "#FFFFFF" 
                font.bold: true
                font.pointSize: 11
            }
        }

        // 2. Contenedor del Logotipo
        Rectangle {
            Layout.preferredWidth: 50
            Layout.preferredHeight: 50
            color: "#030712" 
            radius: 8
            Layout.alignment: Qt.AlignVCenter

            Image {
                anchors.fill: parent
                anchors.margins: 4
                source: root.logo ? root.logo : ""
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 100
                sourceSize.height: 100
                cache: true
                onStatusChanged: if (status === Image.Error || root.logo === "") source = "image://theme/media-playback-start"
            }
        }

        // 3. Nombre del Canal en Negrita
        Text {
            text: root.channelNameStr
            color: root.isCurrent ? "#FFFFFF" : "#F1F5F9" 
            font.bold: true
            font.pointSize: 13 
            Layout.preferredWidth: 160
            elide: Text.ElideRight
            Layout.alignment: Qt.AlignVCenter
        }

        // Línea divisoria vertical
        Rectangle {
            Layout.preferredHeight: 50
            Layout.preferredWidth: 1
            color: "#475569"
            Layout.alignment: Qt.AlignVCenter
        }

        // 4. Bloque Informativo del Programa
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                spacing: 12
                Layout.fillWidth: true

                // Píldora de horario limpia y nítida
                Rectangle {
                    visible: root.hasTime
                    color: "#1E293B"
                    border.color: "#475569"
                    border.width: 1
                    radius: 4
                    Layout.preferredHeight: 22
                    Layout.preferredWidth: timeText.implicitWidth + 14
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        id: timeText
                        anchors.centerIn: parent
                        text: root.extractedTime
                        color: "#60A5FA" 
                        font.bold: true
                        font.pointSize: 10 
                        font.family: "Monospace"
                    }
                }

                Text {
                    text: root.cleanTitle
                    color: "#FFFFFF" 
                    font.bold: true
                    font.pointSize: 13 
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            // 🚀 REFACTORIZACIÓN CRÍTICA CONTRA DESBORDES:
            // Forzamos el auto-ajuste y limitamos a un bloque fijo de 2 líneas de texto de alta densidad
            Text {
                text: root.epgDesc
                color: root.isCurrent ? "#E2E8F0" : "#CBD5E1" 
                font.pointSize: 11 
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }
    }
}
