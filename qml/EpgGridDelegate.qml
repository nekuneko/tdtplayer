// qml/EpgGridDelegate.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    id: root
    width: ListView.view ? ListView.view.width : 600
    height: root.appThemeItem.px((root.isCompact ? 92 : 88) * root.uiScale)
    hoverEnabled: true

    required property int index
    required property string name
    required property string logo
    required property string chNo

    required property var channelModel
    required property int currentChannelIndex
    required property int currentTimestamp
    property real uiScale: 1.0
    property string viewMode: "NOW"
    required property var appThemeItem

    readonly property int itemIndex: root.index
    readonly property bool isCurrent: (ListView.view && ListView.view.currentIndex === root.itemIndex)
                                      || (root.currentChannelIndex === root.itemIndex && (!ListView.view || !ListView.view.activeFocus))
    readonly property bool isCompact: width < root.appThemeItem.px(640)

    property var currentEpgObject: null
    property var nextEpgObject: null

    function forceRefreshEpgData() {
        if (root.channelModel && root.channelNameStr !== "") {
            root.currentEpgObject = root.channelModel.fetch_current_epg(root.channelNameStr);
            root.nextEpgObject = root.channelModel.fetch_next_epg(root.channelNameStr);
        } else {
            root.currentEpgObject = null;
            root.nextEpgObject = null;
        }
    }

    Component.onCompleted: root.forceRefreshEpgData()
    onChannelNameStrChanged: root.forceRefreshEpgData()
    ListView.onReused: root.forceRefreshEpgData()

    background: Rectangle {
        color: root.isCurrent ? root.appThemeItem.bgItemActive : (root.hovered ? root.appThemeItem.bgItemHover : root.appThemeItem.bgItemDefault)
        radius: root.appThemeItem.px(10)
        border.color: root.isCurrent ? root.appThemeItem.borderActive : (root.hovered ? root.appThemeItem.borderHover : root.appThemeItem.borderDefault)
        border.width: root.isCurrent ? 1.5 : 1
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    readonly property string channelNameStr: root.name ? root.name.toString().trim().replace(/[\r\n]/g, "") : ""

    readonly property string nowTitleRaw: root.currentEpgObject ? root.currentEpgObject.title : "Emisión en directo"
    readonly property string nowDescRaw: root.currentEpgObject ? (root.currentEpgObject.description || "Sin descripción disponible.") : "Sin descripción disponible."

    readonly property string nextTitleRaw: root.nextEpgObject ? root.nextEpgObject.title : "Sin datos de programación"
    readonly property string nextDescRaw: root.nextEpgObject ? (root.nextEpgObject.description || "No hay más información disponible.") : "No hay más información disponible."

    readonly property string finalTitleRaw: root.viewMode === "NOW" ? nowTitleRaw : nextTitleRaw
    readonly property string finalDesc: root.viewMode === "NOW" ? nowDescRaw : nextDescRaw

    readonly property int startTimestamp: root.viewMode === "NOW" ? (root.currentEpgObject ? root.currentEpgObject.start_ts : 0) : (root.nextEpgObject ? root.nextEpgObject.start_ts : 0)
    readonly property int stopTimestamp: root.viewMode === "NOW" ? (root.currentEpgObject ? root.currentEpgObject.stop_ts : 0) : (root.nextEpgObject ? root.nextEpgObject.stop_ts : 0)

    readonly property int closeBracketIndex: root.finalTitleRaw.indexOf("]")
    readonly property bool hasTime: root.finalTitleRaw.startsWith("[") && root.closeBracketIndex !== -1

    readonly property string rawTimeStr: hasTime ? root.finalTitleRaw.substring(1, root.closeBracketIndex).trim() : ""
    readonly property string cleanTitle: hasTime ? root.finalTitleRaw.substring(root.closeBracketIndex + 1).trim() : root.finalTitleRaw
    readonly property string formattedTime: root.rawTimeStr.replace(/\s*-\s*/, " ➔ ")

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.appThemeItem.px(12)
        anchors.rightMargin: root.appThemeItem.px(14)
        anchors.topMargin: root.appThemeItem.px(8)
        anchors.bottomMargin: root.appThemeItem.px(8)
        spacing: root.isCompact ? root.appThemeItem.px(10) : root.appThemeItem.px(14)

        EpgBadgeNo {
            textNo: root.chNo ? root.chNo.toString() : root.itemIndex.toString()
            isSelected: root.isCurrent
            themeItem: root.appThemeItem
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            Layout.preferredWidth: root.appThemeItem.px((root.isCompact ? 34 : 38) * root.uiScale)
            Layout.preferredHeight: root.appThemeItem.px((root.isCompact ? 34 : 38) * root.uiScale)
            color: root.appThemeItem.logoBg
            radius: root.appThemeItem.px(8)
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                visible: gridChannelLogo.status === Image.Error || root.logo === ""
                text: root.channelNameStr !== "" ? root.channelNameStr.substring(0, 1).toUpperCase() : "📺"
                color: root.isCurrent ? root.appThemeItem.textTitleActive : root.appThemeItem.textTitle
                font.bold: true
                font.pointSize: root.appThemeItem.pt(11 * root.uiScale)
                renderType: Text.QtRendering
            }

            Image {
                id: gridChannelLogo
                anchors.fill: parent
                anchors.margins: 3
                source: root.logo ? root.logo : ""
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 84
                sourceSize.height: 84
                visible: status === Image.Ready && root.logo !== ""
                cache: true
                asynchronous: true
            }
        }

        Text {
            visible: !root.isCompact
            text: root.channelNameStr
            color: root.isCurrent ? root.appThemeItem.textTitleActive : root.appThemeItem.textTitle
            font.bold: true
            font.pointSize: root.appThemeItem.pt(11 * root.uiScale)
            renderType: Text.NativeRendering
            Layout.preferredWidth: root.appThemeItem.px(130 * root.uiScale)
            elide: Text.ElideRight
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            visible: !root.isCompact
            Layout.preferredHeight: root.appThemeItem.px(40 * root.uiScale)
            Layout.preferredWidth: 1
            color: root.appThemeItem.borderHover
            Layout.alignment: Qt.AlignVCenter
        }

        EpgGridProgramColumn {
            cleanTitle: root.cleanTitle
            finalDesc: root.finalDesc
            hasTime: root.hasTime
            formattedTime: root.formattedTime
            startTimestamp: root.startTimestamp
            stopTimestamp: root.stopTimestamp
            currentTimestamp: root.currentTimestamp
            uiScale: root.uiScale
            viewMode: root.viewMode
            isCurrent: root.isCurrent
            themeItem: root.appThemeItem

            onProgramExpired: {
                root.forceRefreshEpgData();
                root.channelModel.dataChanged(root.channelModel.index(root.itemIndex, 0), root.channelModel.index(root.itemIndex, 0));
            }
        }
    }
}
