// qml/EpgGridDelegate.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    id: root
    width: ListView.view.width
    
    // 🚀 GEOMETRÍA ESCALABLE: Cambiado de 95 fijos a un tamaño proporcional por hardware
    height: root.appThemeItem ? root.appThemeItem.px(95) : 95
    hoverEnabled: true
    
    required property int index
    required property string name
    required property string logo
    required property string chNo

    required property var channelModel
    required property int currentChannelIndex
    property string viewMode: "NOW"

    property var appThemeItem: null

    readonly property int itemIndex: root.index
    readonly property bool isCurrent: ListView.view.currentIndex === root.itemIndex || (root.currentChannelIndex === root.itemIndex && !ListView.view.activeFocus)

    background: Rectangle {
        color: root.isCurrent 
               ? (root.appThemeItem ? root.appThemeItem.bgItemActive : "#FFFFFF") 
               : (root.hovered ? (root.appThemeItem ? root.appThemeItem.bgItemHover : "#334155") : (root.appThemeItem ? root.appThemeItem.bgItemDefault : "#111827"))
        radius: root.appThemeItem ? root.appThemeItem.px(8) : 8
        border.color: root.isCurrent ? (root.appThemeItem ? root.appThemeItem.borderActive : "#FFFFFF") : (root.hovered ? (root.appThemeItem ? root.appThemeItem.borderHover : "#94A3B8") : (root.appThemeItem ? root.appThemeItem.borderDefault : "#1E293B"))
        border.width: root.isCurrent ? 2 : 1
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    readonly property string channelNameStr: root.name ? root.name.toString().trim().replace(/[\r\n]/g, "") : ""
    
    readonly property var nowEpg: root.channelModel ? root.channelModel.fetch_current_epg(root.channelNameStr) : null
    readonly property string nowTitleRaw: nowEpg ? nowEpg.title : "Emisión en directo"
    readonly property string nowDescRaw: nowEpg ? (nowEpg.description || "Sin descripción disponible.") : "Sin descripción disponible."

    readonly property var nextEpg: root.channelModel ? root.channelModel.fetch_next_epg(root.channelNameStr) : null
    readonly property string nextTitleRaw: nextEpg ? nextEpg.title : "Sin datos de programación"
    readonly property string nextDescRaw: nextEpg ? (nextEpg.description || "No hay más información disponible.") : "No hay más información disponible."

    readonly property string finalTitleRaw: root.viewMode === "NOW" ? nowTitleRaw : nextTitleRaw
    readonly property string finalDesc: root.viewMode === "NOW" ? nowDescRaw : nextDescRaw

    readonly property int closeBracketIndex: root.finalTitleRaw.indexOf("]")
    readonly property bool hasTime: root.finalTitleRaw.startsWith("[") && root.closeBracketIndex !== -1
    
    readonly property string rawTimeStr: hasTime ? root.finalTitleRaw.substring(1, root.closeBracketIndex).trim() : ""
    readonly property string cleanTitle: hasTime ? root.finalTitleRaw.substring(root.closeBracketIndex + 1).trim() : root.finalTitleRaw
    readonly property string formattedTime: root.rawTimeStr.replace(/\s*-\s*/, " ➔ ")

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.margins: root.appThemeItem ? root.appThemeItem.px(16) : 16
        spacing: root.appThemeItem ? root.appThemeItem.px(20) : 20

        // 1. Número de Canal con Badge Proporcional
        Rectangle {
            color: root.isCurrent ? (root.appThemeItem ? root.appThemeItem.bgAbsolute : "#000000") : (root.appThemeItem ? root.appThemeItem.badgeTimeBg : "#334155")
            radius: 4
            Layout.preferredWidth: root.appThemeItem ? root.appThemeItem.px(38) : 38
            Layout.preferredHeight: root.appThemeItem ? root.appThemeItem.px(24) : 24
            Layout.alignment: Qt.AlignVCenter
            Text {
                anchors.centerIn: parent; text: root.chNo ? root.chNo.toString().padStart(2, '0') : root.itemIndex.toString().padStart(2, '0')
                color: "#FFFFFF"; font.bold: true
                font.pointSize: root.appThemeItem ? root.appThemeItem.pt(10) : 10
                renderType: Text.NativeRendering
            }
        }

        // 2. Contenedor del Logotipo Proporcional
        Rectangle {
            Layout.preferredWidth: root.appThemeItem ? root.appThemeItem.px(45) : 45
            Layout.preferredHeight: root.appThemeItem ? root.appThemeItem.px(45) : 45
            color: root.appThemeItem ? root.appThemeItem.bgAbsolute : "#000000"; radius: 6; Layout.alignment: Qt.AlignVCenter
            Image {
                anchors.fill: parent; anchors.margins: 4; source: root.logo ? root.logo : ""
                fillMode: Image.PreserveAspectFit; sourceSize.width: 90; sourceSize.height: 90; cache: true
                onStatusChanged: if (status === Image.Error || root.logo === "") source = "image://theme/media-playback-start"
            }
        }

        // 3. Nombre del Canal con Tipografía Escalable
        Text {
            text: root.channelNameStr
            color: root.isCurrent ? (root.appThemeItem ? root.appThemeItem.textTitleActive : "#000000") : (root.appThemeItem ? root.appThemeItem.textTitle : "#FFFFFF")
            font.bold: true
            font.pointSize: root.appThemeItem ? root.appThemeItem.pt(12) : 12
            renderType: Text.NativeRendering
            Layout.preferredWidth: root.appThemeItem ? root.appThemeItem.px(150) : 150
            elide: Text.ElideRight; Layout.alignment: Qt.AlignVCenter
        }

        Rectangle { 
            Layout.preferredHeight: root.appThemeItem ? root.appThemeItem.px(45) : 45
            Layout.preferredWidth: 1; color: root.appThemeItem ? root.appThemeItem.borderHover : "#475569"; Layout.alignment: Qt.AlignVCenter 
        }

        // 4. Bloque Informativo Escalable
        ColumnLayout {
            Layout.fillWidth: true; spacing: root.appThemeItem ? root.appThemeItem.px(6) : 6; Layout.alignment: Qt.AlignVCenter

            RowLayout {
                spacing: root.appThemeItem ? root.appThemeItem.px(12) : 12; Layout.fillWidth: true

                // Cápsula Horaria Premium Escalable por Hardware
                Rectangle {
                    id: timeLabelBox
                    visible: root.hasTime
                    color: root.isCurrent ? "transparent" : (root.appThemeItem ? root.appThemeItem.badgeTimeBg : "#1E293B")
                    border.color: root.isCurrent ? "#FFFFFF" : (root.appThemeItem ? root.appThemeItem.borderHover : "#475569")
                    border.width: 1
                    radius: 5

                    Layout.preferredHeight: root.appThemeItem ? root.appThemeItem.px(24) : 24
                    Layout.preferredWidth: timeText.implicitWidth + (root.appThemeItem ? root.appThemeItem.px(14) : 14)
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        id: timeText
                        anchors.centerIn: parent
                        text: root.formattedTime
                        color: root.isCurrent ? "#FFFFFF" : (root.appThemeItem ? root.appThemeItem.badgeTimeText : "#60A5FA")
                        font.bold: true
                        font.pointSize: root.appThemeItem ? root.appThemeItem.pt(10) : 10
                        font.family: "Monospace"
                        renderType: Text.NativeRendering 
                    }
                }

                Text {
                    text: root.cleanTitle
                    color: root.isCurrent ? (root.appThemeItem ? root.appThemeItem.textTitleActive : "#000000") : (root.appThemeItem ? root.appThemeItem.textTitle : "#FFFFFF")
                    font.bold: true
                    font.pointSize: root.appThemeItem ? root.appThemeItem.pt(12.5) : 12.5
                    renderType: Text.NativeRendering
                    Layout.fillWidth: true; elide: Text.ElideRight; Layout.alignment: Qt.AlignVCenter
                }
            }

            Text {
                text: root.finalDesc
                color: root.isCurrent ? (root.appThemeItem ? root.appThemeItem.textDescActive : "#111827") : (root.appThemeItem ? root.appThemeItem.textDesc : "#CBD5E1")
                font.pointSize: root.appThemeItem ? root.appThemeItem.pt(10.5) : 10.5
                renderType: Text.NativeRendering
                Layout.fillWidth: true
                wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
            }
        }
    }
}
