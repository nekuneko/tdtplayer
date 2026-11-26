// qml/EpgGridHeader.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    Layout.fillWidth: true
    spacing: root.appThemeItem ? root.appThemeItem.px(12 * uiScale) : 12

    required property var appThemeItem
    required property string currentViewMode
    required property bool isCompactHeader
    required property real containerWidth
    property real uiScale: 1.0

    signal viewModeSelected(string mode)

    Text {
        text: root.isCompactHeader ? "GUÍA TV" : "GUÍA DE PROGRAMACIÓN"
        color: root.appThemeItem.textTitle
        font.bold: true
        font.pointSize: root.appThemeItem.pt((root.isCompactHeader ? 13 : 15) * root.uiScale)
        font.letterSpacing: 1.3
        elide: Text.ElideRight
        Layout.minimumWidth: 0
    }

    RowLayout {
        spacing: root.appThemeItem.px(8)

        Repeater {
            model: [
                { mode: "NOW", compactText: "Ahora", fullText: "Emitiéndose Ahora", compactW: 82, fullW: 145 },
                { mode: "NEXT", compactText: "Siguiente ➔", fullText: "A Continuación ➔", compactW: 100, fullW: 145 }
            ]

            delegate: Button {
                required property var modelData
                readonly property bool isSelected: root.currentViewMode === modelData.mode

                text: root.isCompactHeader ? modelData.compactText : modelData.fullText
                font.bold: true
                font.pointSize: root.appThemeItem.pt(10 * root.uiScale)
                focusPolicy: Qt.NoFocus
                onClicked: root.viewModeSelected(modelData.mode)

                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: parent.isSelected
                           ? root.appThemeItem.getW3cContrast(root.appThemeItem.bgItemActive)
                           : root.appThemeItem.textDesc
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    implicitWidth: root.appThemeItem.px((root.isCompactHeader ? modelData.compactW : modelData.fullW) * root.uiScale)
                    implicitHeight: root.appThemeItem.px(30 * root.uiScale)
                    color: parent.isSelected ? root.appThemeItem.bgItemActive : root.appThemeItem.bgItemDefault
                    border.color: parent.isSelected ? root.appThemeItem.borderActive : root.appThemeItem.borderDefault
                    border.width: 1
                    radius: root.appThemeItem.px(8)
                }
            }
        }
    }

    Item { Layout.fillWidth: true }

    Text {
        visible: root.containerWidth >= (root.appThemeItem ? root.appThemeItem.px(560) : 560)
        text: root.isCompactHeader ? "TAB | ESC" : "TAB: Alternar | E / ESC: Volver"
        color: root.appThemeItem.textDesc
        font.pointSize: root.appThemeItem.pt(9.5 * root.uiScale)
        font.bold: true
        Layout.alignment: Qt.AlignVCenter
    }

    ClockWidget {
        themeItem: root.appThemeItem
        fontPt: root.appThemeItem ? root.appThemeItem.pt(10 * root.uiScale) : 10
        pillHeight: root.appThemeItem ? root.appThemeItem.px(30 * root.uiScale) : 30
        Layout.alignment: Qt.AlignVCenter
    }
}
