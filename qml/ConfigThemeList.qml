// qml/ConfigThemeList.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ListView {
    id: root

    required property var appThemeItem
    required property var appSettingsItem

    Layout.fillWidth: true
    Layout.fillHeight: true
    model: root.appThemeItem ? root.appThemeItem.themeKeys : []
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    spacing: root.appThemeItem ? root.appThemeItem.px(6) : 6

    delegate: ItemDelegate {
        id: themeBtnDelegate
        width: root.width
        height: root.appThemeItem ? root.appThemeItem.px(34) : 34
        hoverEnabled: true

        readonly property string themeKey: modelData
        readonly property bool isSelected: root.appThemeItem && root.appThemeItem.currentTheme === themeBtnDelegate.themeKey
        readonly property var themeObj: (root.appThemeItem && root.appThemeItem.colors[themeBtnDelegate.themeKey]) ? root.appThemeItem.colors[themeBtnDelegate.themeKey] : null

        background: Rectangle {
            color: themeBtnDelegate.isSelected
                   ? appTheme.bgItemActive
                   : (themeBtnDelegate.hovered ? appTheme.bgItemHover : appTheme.bgItemDefault)
            radius: root.appThemeItem ? root.appThemeItem.px(10) : 10
            border.color: themeBtnDelegate.isSelected
                          ? appTheme.borderActive
                          : (themeBtnDelegate.hovered ? appTheme.borderHover : appTheme.borderDefault)
            border.width: themeBtnDelegate.isSelected ? 1.5 : 1
        }

        contentItem: RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.appThemeItem ? root.appThemeItem.px(10) : 10
            anchors.rightMargin: root.appThemeItem ? root.appThemeItem.px(10) : 10
            spacing: root.appThemeItem ? root.appThemeItem.px(10) : 10

            Rectangle {
                Layout.preferredWidth: root.appThemeItem ? root.appThemeItem.px(11) : 11
                Layout.preferredHeight: root.appThemeItem ? root.appThemeItem.px(11) : 11
                radius: Layout.preferredWidth / 2
                color: themeBtnDelegate.themeObj ? themeBtnDelegate.themeObj["bgItemActive"] : appTheme.bgItemActive
                border.color: themeBtnDelegate.isSelected ? appTheme.textTitleActive : appTheme.borderHover
                border.width: 1
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: themeBtnDelegate.themeObj ? themeBtnDelegate.themeObj["name"] : themeBtnDelegate.themeKey
                color: themeBtnDelegate.isSelected ? appTheme.textTitleActive : appTheme.textTitle
                font.bold: themeBtnDelegate.isSelected
                font.pointSize: root.appThemeItem ? root.appThemeItem.pt(9.5) : 9.5
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                renderType: Text.NativeRendering
            }
        }

        onClicked: {
            if (root.appThemeItem && root.appSettingsItem) {
                root.appThemeItem.currentTheme = themeBtnDelegate.themeKey;
                root.appSettingsItem.lastTheme = themeBtnDelegate.themeKey;
            }
        }
    }
}
