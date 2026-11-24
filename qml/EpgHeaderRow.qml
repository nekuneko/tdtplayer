// qml/EpgHeaderRow.qml
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    Layout.fillWidth: true
    spacing: 12

    required property bool isFullScreen
    required property string channelNo
    required property string channelName
    required property string hoveredChannelName

    // 🚀 SOLUCCIÓN DEFINITIVA: Cambiado de 'required property' a propiedad estándar con buffer vacío
    // Esto permite que el Component.onCompleted de tu EpgDrawer le inyecte el Binding dinámico sin errores de arranque
    property string epgTitle: ""

    readonly property bool isCompact: root.width < (appTheme ? appTheme.px(360) : 360)

    // Bloque Izquierdo: [Número] Nombre del Canal — Programa Activo
    RowLayout {
        spacing: 8
        Layout.alignment: Qt.AlignLeft
        Layout.fillWidth: true
        Layout.minimumWidth: 0

        Rectangle {
            visible: root.channelNo !== ""
            color: appTheme.bgItemActive
            radius: appTheme.px ? appTheme.px(6) : 6
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: root.channelNo.padStart(2, '0')
                color: appTheme.getW3cContrast(parent.color)
                font.bold: true
                font.pointSize: 11
                renderType: Text.NativeRendering
            }
        }

        Text {
            text: root.hoveredChannelName !== "" ? root.hoveredChannelName : root.channelName
            color: appTheme.textTitle
            font.bold: true
            font.pointSize: root.isFullScreen ? 14 : 12
            renderType: Text.NativeRendering
            elide: Text.ElideRight
            Layout.minimumWidth: 0
            Layout.maximumWidth: root.cleanTitleText !== "" ? (root.width * 0.42) : root.width
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: root.cleanTitleText !== ""
            text: "—"
            color: appTheme.textDesc
            font.pointSize: root.isFullScreen ? 14 : 12
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.cleanTitleText
            color: "#FFFFFF"
            font.bold: true
            font.pointSize: root.isFullScreen ? 14 : 12
            renderType: Text.NativeRendering
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.alignment: Qt.AlignVCenter
        }
    }

    readonly property int _closeBracketIndex: root.epgTitle.indexOf("]")
    readonly property bool _hasTime: root.epgTitle.startsWith("[") && root._closeBracketIndex !== -1
    readonly property string cleanTitleText: root._hasTime ? root.epgTitle.substring(root._closeBracketIndex + 1).trim() : root.epgTitle

    Item {
        Layout.fillWidth: false
    }

    RowLayout {
        visible: !root.isCompact
        spacing: 16
        Layout.alignment: Qt.AlignRight

        EpgVolumeSlider {
            isFullScreen: root.isFullScreen
        }
    }
}
