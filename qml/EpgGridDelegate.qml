// qml/EpgGridDelegate.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    id: root
    width: ListView.view.width
    height: root.appThemeItem ? root.appThemeItem.px(100) : 105
    hoverEnabled: true

    required property int index
    required property string name
    required property string logo
    required property string chNo

    required property var channelModel
    required property int currentChannelIndex
    property string viewMode: "NOW"
    required property var appThemeItem

    readonly property int itemIndex: root.index
    readonly property bool isCurrent: ListView.view.currentIndex === root.itemIndex || (root.currentChannelIndex === root.itemIndex && !ListView.view.activeFocus)

    property int currentTimestamp: Math.floor(Date.now() / 1000)

    Timer {
        id: liveProgressTimer
        interval: 1000
        running: root.visible && root.viewMode === "NOW"
        repeat: true
        onTriggered: root.currentTimestamp = Math.floor(Date.now() / 1000)
    }

    background: Rectangle {
        // Al ser 'required', el objeto siempre existe en memoria. Cero rodeos.
        color: root.isCurrent 
               ? root.appThemeItem.bgItemActive 
               : root.hovered 
                 ? root.appThemeItem.bgItemHover 
                 : root.appThemeItem.bgItemDefault
        
        radius: root.appThemeItem.px(8)
        border.color: root.isCurrent 
                      ? root.appThemeItem.borderActive 
                      : root.hovered 
                        ? root.appThemeItem.borderHover 
                        : root.appThemeItem.borderDefault
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

    readonly property int startTimestamp: root.viewMode === "NOW" ? (nowEpg ? nowEpg.start_ts : 0) : (nextEpg ? nextEpg.start_ts : 0)
    readonly property int stopTimestamp: root.viewMode === "NOW" ? (nowEpg ? nowEpg.stop_ts : 0) : (nextEpg ? nextEpg.stop_ts : 0)

    readonly property int closeBracketIndex: root.finalTitleRaw.indexOf("]")
    readonly property bool hasTime: root.finalTitleRaw.startsWith("[") && root.closeBracketIndex !== -1

    readonly property string rawTimeStr: hasTime ? root.finalTitleRaw.substring(1, root.closeBracketIndex).trim() : ""
    readonly property string cleanTitle: hasTime ? root.finalTitleRaw.substring(root.closeBracketIndex + 1).trim() : root.finalTitleRaw
    readonly property string formattedTime: root.rawTimeStr.replace(/\s*-\s*/, " ➔ ")

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.appThemeItem ? root.appThemeItem.px(16) : 16
        anchors.rightMargin: root.appThemeItem ? root.appThemeItem.px(36) : 36
        anchors.topMargin: root.appThemeItem ? root.appThemeItem.px(12) : 12
        anchors.bottomMargin: root.appThemeItem ? root.appThemeItem.px(12) : 12
        spacing: root.appThemeItem ? root.appThemeItem.px(20) : 20
        EpgBadgeNo {
            textNo: root.chNo ? root.chNo.toString() : root.itemIndex.toString()
            isSelected: root.isCurrent
            themeItem: root.appThemeItem
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            Layout.preferredWidth: root.appThemeItem ? root.appThemeItem.px(45) : 45
            Layout.preferredHeight: root.appThemeItem ? root.appThemeItem.px(45) : 45
            color: root.appThemeItem ? root.appThemeItem.bgAbsolute : "#000000"
            radius: 6
            Layout.alignment: Qt.AlignVCenter

            Image {
                anchors.fill: parent
                anchors.margins: 4
                source: root.logo ? root.logo : ""
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 90
                sourceSize.height: 90
                cache: true
                onStatusChanged: {
                    if (status === Image.Error || root.logo === "") {
                        source = "image://theme/media-playback-start";
                    }
                }
            }
        }

        Text {
            text: root.channelNameStr
            color: root.isCurrent ? (root.appThemeItem ? root.appThemeItem.textTitleActive : "#000000") : (root.appThemeItem ? root.appThemeItem.textTitle : "#FFFFFF")
            font.bold: true
            font.pointSize: root.appThemeItem ? root.appThemeItem.pt(12) : 12
            renderType: Text.NativeRendering
            Layout.preferredWidth: root.appThemeItem ? root.appThemeItem.px(130) : 130
            elide: Text.ElideRight
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            Layout.preferredHeight: root.appThemeItem ? root.appThemeItem.px(45) : 45
            Layout.preferredWidth: 1
            color: root.appThemeItem ? root.appThemeItem.borderHover : "#475569"
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: root.appThemeItem ? root.appThemeItem.px(4) : 4
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                spacing: root.appThemeItem ? root.appThemeItem.px(12) : 12
                Layout.fillWidth: true

                EpgTimePill {
                    isSelected: root.isCurrent
                    hasValidTime: root.hasTime && root.viewMode === "NOW"
                    timeTextStr: root.formattedTime
                    stopTime: root.stopTimestamp
                    themeItem: root.appThemeItem
                    Layout.alignment: Qt.AlignVCenter

                    onProgramExpired: {
                        root.channelModel.dataChanged(root.channelModel.index(root.itemIndex, 0), root.channelModel.index(root.itemIndex, 0));
                    }
                }

                Text {
                    text: root.cleanTitle
                    color: root.isCurrent ? (root.appThemeItem ? root.appThemeItem.textTitleActive : "#000000") : (root.appThemeItem ? root.appThemeItem.textTitle : "#FFFFFF")
                    font.bold: true
                    font.pointSize: root.appThemeItem ? root.appThemeItem.pt(12.5) : 12.5
                    renderType: Text.NativeRendering
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Text {
                text: root.finalDesc
                color: root.isCurrent ? (root.appThemeItem ? root.appThemeItem.textDescActive : "#111827") : (root.appThemeItem ? root.appThemeItem.textDesc : "#CBD5E1")
                font.pointSize: root.appThemeItem ? root.appThemeItem.pt(10.5) : 10.5
                renderType: Text.NativeRendering
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                maximumLineCount: 1
                elide: Text.ElideRight
            }

            Rectangle {
                id: gridProgressBarContainer
                visible: root.hasTime && root.viewMode === "NOW" && root.stopTimestamp > root.startTimestamp
                Layout.fillWidth: true
                Layout.preferredHeight: root.appThemeItem ? root.appThemeItem.px(4) : 4
                Layout.topMargin: root.appThemeItem ? root.appThemeItem.px(2) : 2
                color: root.isCurrent ? "rgba(255, 255, 255, 0.3)" : "#334155"
                radius: 2

                readonly property real progressFactor: Math.max(0.0, Math.min(1.0, (root.currentTimestamp - root.startTimestamp) / (root.stopTimestamp - root.startTimestamp)))

                Rectangle {
                    width: parent.width * parent.progressFactor
                    height: parent.height
                    radius: 2
                    color: root.isCurrent ? "#FFFFFF" : (root.appThemeItem ? root.appThemeItem.borderActive : "#60A5FA")
                }
            }
        }
    }
}
