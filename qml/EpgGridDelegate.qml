// qml/EpgGridDelegate.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    id: root
    width: ListView.view.width
    height: 95 
    hoverEnabled: true
    
    required property int index
    required property string name
    required property string logo
    required property string chNo

    required property var channelModel
    required property int currentChannelIndex
    
    // 🚀 RESTAURACIÓN CRÍTICA: Propiedad reactiva para enlazar las pestañas del Overlay superior
    property string viewMode: "NOW"

    readonly property int itemIndex: root.index
    readonly property bool isCurrent: ListView.view.currentIndex === root.itemIndex || (root.currentChannelIndex === root.itemIndex && !ListView.view.activeFocus)

    background: Rectangle {
        color: root.isCurrent ? appTheme.bgItemActive : (root.hovered ? appTheme.bgItemHover : appTheme.bgItemDefault)
        radius: 8
        border.color: root.isCurrent ? appTheme.borderActive : (root.hovered ? appTheme.borderHover : appTheme.borderDefault)
        border.width: root.isCurrent ? 2 : 1
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    readonly property string channelNameStr: root.name ? root.name.toString().trim().replace(/[\r\n]/g, "") : ""
    
    // Consultas SQLite a Python dependiendo de la pestaña activa
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
    
    readonly property string extractedTime: hasTime ? root.finalTitleRaw.substring(0, root.closeBracketIndex + 1) : ""
    readonly property string cleanTitle: hasTime ? root.finalTitleRaw.substring(root.closeBracketIndex + 1).trim() : root.finalTitleRaw

    contentItem: RowLayout {
        anchors.fill: parent; anchors.margins: 16; spacing: 20

        Rectangle {
            color: root.isCurrent ? appTheme.bgAbsolute : appTheme.badgeTimeBg 
            radius: 4; Layout.preferredWidth: 38; Layout.preferredHeight: 24; Layout.alignment: Qt.AlignVCenter
            Text {
                anchors.centerIn: parent; text: root.chNo ? root.chNo.toString().padStart(2, '0') : root.itemIndex.toString().padStart(2, '0')
                color: "#FFFFFF"; font.bold: true; font.pointSize: 10; renderType: Text.NativeRendering
            }
        }

        Rectangle {
            Layout.preferredWidth: 45; Layout.preferredHeight: 45; color: appTheme.bgAbsolute; radius: 6; Layout.alignment: Qt.AlignVCenter
            Image {
                anchors.fill: parent; anchors.margins: 4; source: root.logo ? root.logo : ""
                fillMode: Image.PreserveAspectFit; sourceSize.width: 90; sourceSize.height: 90; cache: true
                onStatusChanged: if (status === Image.Error || root.logo === "") source = "image://theme/media-playback-start"
            }
        }

        Text {
            text: root.channelNameStr
            color: root.isCurrent ? appTheme.textTitleActive : appTheme.textTitle 
            font.bold: true; font.pointSize: 12; Layout.preferredWidth: 150
            renderType: Text.NativeRendering
            elide: Text.ElideRight; Layout.alignment: Qt.AlignVCenter
        }

        Rectangle { Layout.preferredHeight: 45; Layout.preferredWidth: 1; color: appTheme.borderHover; Layout.alignment: Qt.AlignVCenter }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 6; Layout.alignment: Qt.AlignVCenter

            RowLayout {
                spacing: 12; Layout.fillWidth: true

                Rectangle {
                    visible: root.hasTime
                    color: root.isCurrent ? appTheme.bgAbsolute : appTheme.badgeTimeBg
                    border.color: root.isCurrent ? appTheme.bgAbsolute : appTheme.borderHover
                    border.width: 1; radius: 4; Layout.preferredHeight: 22; Layout.preferredWidth: timeText.implicitWidth + 14; Layout.alignment: Qt.AlignVCenter

                    Text {
                        id: timeText; anchors.centerIn: parent; text: root.extractedTime
                        color: root.isCurrent ? appTheme.textTitle : appTheme.badgeTimeText
                        font.bold: true; font.pointSize: 10; font.family: "Monospace"; renderType: Text.NativeRendering
                    }
                }

                Text {
                    text: root.cleanTitle
                    color: root.isCurrent ? appTheme.textTitleActive : appTheme.textTitle
                    font.bold: true; font.pointSize: 12.5; renderType: Text.NativeRendering
                    Layout.fillWidth: true; elide: Text.ElideRight; Layout.alignment: Qt.AlignVCenter
                }
            }

            Text {
                text: root.finalDesc
                color: root.isCurrent ? appTheme.textDescActive : appTheme.textDesc 
                font.pointSize: 10.5; renderType: Text.NativeRendering
                Layout.fillWidth: true
                wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
            }
        }
    }
}
