// qml/EpgGridOverlay.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: root
    anchors.fill: parent
    visible: false
    opacity: 0.0
    objectName: "epgGridOverlayLoader"

    required property var channelModel
    required property int currentChannelIndex
    property string currentViewMode: "NOW"

    // Contrato estricto: El tema es obligatorio para el renderizado
    required property var appThemeItem

    signal channelSelected(int realIndex)
    signal closeRequested

    Behavior on opacity {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    onVisibleChanged: {
        if (visible) {
            root.opacity = 0.96;
            root.currentViewMode = "NOW";
            overlayListView.forceActiveFocus();
            // 🚀 LIMPIEZA: Enlace directo al controlador global sin comprobaciones redundantes
            root.currentChannelIndex = ctrl.currentChannelIndex;

            if (root.currentChannelIndex >= 0 && root.currentChannelIndex < root.channelModel.rowCount()) {
                overlayListView.currentIndex = root.currentChannelIndex;
                overlayListView.positionViewAtIndex(root.currentChannelIndex, ListView.Center);
            }
        } else {
            root.opacity = 0.0;
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_E) {
            root.closeRequested();
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab) {
            root.currentViewMode = root.currentViewMode === "NOW" ? "NEXT" : "NOW";
            event.accepted = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.appThemeItem.bgAbsolute
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onWheel: event => event.accepted = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 50
        spacing: 24
        RowLayout {
            Layout.fillWidth: true
            spacing: 30

            Text {
                text: "GUÍA DE PROGRAMACIÓN"
                color: root.appThemeItem.textTitle
                font.bold: true
                font.pointSize: 18
                font.letterSpacing: 2
            }

            RowLayout {
                spacing: 8

                Button {
                    id: nowTabBtn
                    text: "Emitiéndose Ahora"
                    font.bold: true
                    font.pointSize: 11
                    focusPolicy: Qt.NoFocus
                    contentItem: Text {
                        text: nowTabBtn.text
                        font: nowTabBtn.font
                        color: root.currentViewMode === "NOW" ? root.appThemeItem.getW3cContrast(root.appThemeItem.bgItemActive) : root.appThemeItem.textDesc
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        implicitWidth: 160
                        implicitHeight: 36
                        color: root.currentViewMode === "NOW" ? root.appThemeItem.bgItemActive : "transparent"
                        border.color: root.appThemeItem.textTitle
                        border.width: 2
                        radius: 6
                    }
                    onClicked: root.currentViewMode = "NOW"
                }

                Button {
                    id: nextTabBtn
                    text: "A Continuación ➔"
                    font.bold: true
                    font.pointSize: 11
                    focusPolicy: Qt.NoFocus
                    contentItem: Text {
                        text: nextTabBtn.text
                        font: nextTabBtn.font
                        color: root.currentViewMode === "NEXT" ? root.appThemeItem.getW3cContrast(root.appThemeItem.bgItemActive) : root.appThemeItem.textDesc
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        implicitWidth: 160
                        implicitHeight: 36
                        color: root.currentViewMode === "NEXT" ? root.appThemeItem.bgItemActive : "transparent"
                        border.color: root.appThemeItem.textTitle
                        border.width: 2
                        radius: 6
                    }
                    onClicked: root.currentViewMode = "NEXT"
                }
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                text: "TAB: Alternar | E/ESC: Volver"
                color: root.appThemeItem.textDesc
                font.pointSize: 11
                font.bold: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 2
            color: root.appThemeItem.textTitle
        }

        ListView {
            id: overlayListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.channelModel
            clip: true
            spacing: 12
            boundsBehavior: Flickable.StopAtBounds
            focus: true

            delegate: EpgGridDelegate {
                channelModel: root.channelModel
                currentChannelIndex: root.currentChannelIndex
                viewMode: root.currentViewMode
                onClicked: root.channelSelected(itemIndex)
                appThemeItem: root.appThemeItem
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOn
                contentItem: Rectangle {
                    implicitWidth: 6
                    radius: 3
                    color: root.appThemeItem.textTitle
                }
            }
        }
    }
}
