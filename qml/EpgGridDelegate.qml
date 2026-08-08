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

    // 🚀 VARIABLES REACTIVAS DE CONTROL: Sacamos el EPG de las propiedades fijas y las volvemos dinámicas
    property var currentEpgObject: null
    property var nextEpgObject: null

    // Función interna encargada de destrozar la caché e invocar al cursor WAL de SQLite de forma forzada
    function forceRefreshEpgData() {
        if (root.channelModel && root.channelNameStr !== "") {
            root.currentEpgObject = root.channelModel.fetch_current_epg(root.channelNameStr);
            root.nextEpgObject = root.channelModel.fetch_next_epg(root.channelNameStr);
        }
    }

    // Inicializamos los datos al completarse el árbol de renderizado de la tarjeta
    Component.onCompleted: {
        root.forceRefreshEpgData();
    }

    Timer {
        id: liveProgressTimer
        interval: 1000
        running: root.visible && root.viewMode === "NOW"
        repeat: true
        onTriggered: root.currentTimestamp = Math.floor(Date.now() / 1000)
    }

    background: Rectangle {
        color: root.isCurrent ? root.appThemeItem.bgItemActive : (root.hovered ? root.appThemeItem.bgItemHover : root.appThemeItem.bgItemDefault)

        radius: root.appThemeItem.px(8)
        border.color: root.isCurrent ? root.appThemeItem.borderActive : (root.hovered ? root.appThemeItem.borderHover : root.appThemeItem.borderDefault)
        border.width: root.isCurrent ? 2 : 1
        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    readonly property string channelNameStr: root.name ? root.name.toString().trim().replace(/[\r\n]/g, "") : ""

    // Vinculamos los textos de la interfaz a nuestras nuevas propiedades dinámicas reactivas
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
        anchors.leftMargin: root.appThemeItem.px(16)
        anchors.rightMargin: root.appThemeItem.px(36)
        anchors.topMargin: root.appThemeItem.px(12)
        anchors.bottomMargin: root.appThemeItem.px(12)
        spacing: root.appThemeItem.px(20)

        EpgBadgeNo {
            textNo: root.chNo ? root.chNo.toString() : root.itemIndex.toString()
            isSelected: root.isCurrent
            themeItem: root.appThemeItem
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            Layout.preferredWidth: root.appThemeItem.px(45)
            Layout.preferredHeight: root.appThemeItem.px(45)
            color: root.appThemeItem.bgAbsolute
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
            color: root.isCurrent ? root.appThemeItem.textTitleActive : root.appThemeItem.textTitle
            font.bold: true
            font.pointSize: root.appThemeItem.pt(12)
            renderType: Text.NativeRendering
            Layout.preferredWidth: root.appThemeItem.px(130)
            elide: Text.ElideRight
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            Layout.preferredHeight: root.appThemeItem.px(45)
            Layout.preferredWidth: 1
            color: root.appThemeItem.borderHover
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: root.appThemeItem.px(4)
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                spacing: root.appThemeItem.px(12)
                Layout.fillWidth: true

                EpgTimePill {
                    isSelected: root.isCurrent
                    hasValidTime: root.hasTime && root.viewMode === "NOW"
                    timeTextStr: root.formattedTime
                    stopTime: root.stopTimestamp
                    themeItem: root.appThemeItem
                    Layout.alignment: Qt.AlignVCenter

                    // 🚀 SOLUCIÓN: Cuando expira la hora, forzamos la llamada directa para sobreescribir la memoria de Qt6
                    onProgramExpired: {
                        root.forceRefreshEpgData();
                        root.channelModel.dataChanged(root.channelModel.index(root.itemIndex, 0), root.channelModel.index(root.itemIndex, 0));
                    }
                }

                Text {
                    text: root.cleanTitle
                    color: root.isCurrent ? root.appThemeItem.textTitleActive : root.appThemeItem.textTitle
                    font.bold: true
                    font.pointSize: root.appThemeItem.pt(12.5)
                    renderType: Text.NativeRendering
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Text {
                text: root.finalDesc
                color: root.isCurrent ? root.appThemeItem.textDescActive : root.appThemeItem.textDesc
                font.pointSize: root.appThemeItem.pt(10.5)
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
                Layout.preferredHeight: root.appThemeItem.px(4)
                Layout.topMargin: root.appThemeItem.px(2)
                color: root.isCurrent ? "rgba(255, 255, 255, 0.3)" : "#334155"
                radius: 2

                readonly property real progressFactor: Math.max(0.0, Math.min(1.0, (root.currentTimestamp - root.startTimestamp) / (root.stopTimestamp - root.startTimestamp)))

                Rectangle {
                    width: parent.width * parent.progressFactor
                    height: parent.height
                    radius: 2
                    color: root.isCurrent ? "#FFFFFF" : root.appThemeItem.borderActive
                }
            }
        }
    }
}
