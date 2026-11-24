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

    readonly property real outerMargin: root.appThemeItem ? root.appThemeItem.px(12) : 12
    readonly property real effectiveWidth: parent ? parent.width : width
    readonly property bool isCompactHeader: effectiveWidth < (root.appThemeItem ? root.appThemeItem.px(980) : 980)

    Behavior on opacity {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    onVisibleChanged: {
        if (visible) {
            root.opacity = 0.98;
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
        color: "black"
        opacity: 0.55
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onWheel: event => event.accepted = true
    }

    Rectangle {
        id: gridCardContainer
        anchors.fill: parent
        anchors.margins: root.outerMargin
        color: root.appThemeItem.bgAbsolute
        radius: root.appThemeItem ? root.appThemeItem.px(16) : 16
        border.color: root.appThemeItem.borderDefault
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.isCompactHeader ? root.appThemeItem.px(16) : root.appThemeItem.px(24)
            spacing: root.appThemeItem.px(16)

            RowLayout {
                Layout.fillWidth: true
                spacing: root.appThemeItem.px(16)

                Text {
                    text: root.isCompactHeader ? "GUÍA TV" : "GUÍA DE PROGRAMACIÓN"
                    color: root.appThemeItem.textTitle
                    font.bold: true
                    font.pointSize: root.isCompactHeader ? root.appThemeItem.pt(14) : root.appThemeItem.pt(16)
                    font.letterSpacing: 1.5
                    elide: Text.ElideRight
                    Layout.minimumWidth: 0
                }

                RowLayout {
                    spacing: root.appThemeItem.px(8)

                    Button {
                        id: nowTabBtn
                        text: root.isCompactHeader ? "Ahora" : "Emitiéndose Ahora"
                        font.bold: true
                        font.pointSize: root.appThemeItem.pt(10.5)
                        focusPolicy: Qt.NoFocus
                        contentItem: Text {
                            text: nowTabBtn.text
                            font: nowTabBtn.font
                            color: root.currentViewMode === "NOW" ? root.appThemeItem.getW3cContrast(root.appThemeItem.bgItemActive) : root.appThemeItem.textDesc
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            implicitWidth: root.isCompactHeader ? root.appThemeItem.px(95) : root.appThemeItem.px(155)
                            implicitHeight: root.appThemeItem.px(34)
                            color: root.currentViewMode === "NOW" ? root.appThemeItem.bgItemActive : root.appThemeItem.bgItemDefault
                            border.color: root.currentViewMode === "NOW" ? root.appThemeItem.borderActive : root.appThemeItem.borderDefault
                            border.width: 1
                            radius: root.appThemeItem.px(8)
                        }
                        onClicked: root.currentViewMode = "NOW"
                    }

                    Button {
                        id: nextTabBtn
                        text: root.isCompactHeader ? "Siguiente ➔" : "A Continuación ➔"
                        font.bold: true
                        font.pointSize: root.appThemeItem.pt(10.5)
                        focusPolicy: Qt.NoFocus
                        contentItem: Text {
                            text: nextTabBtn.text
                            font: nextTabBtn.font
                            color: root.currentViewMode === "NEXT" ? root.appThemeItem.getW3cContrast(root.appThemeItem.bgItemActive) : root.appThemeItem.textDesc
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            implicitWidth: root.isCompactHeader ? root.appThemeItem.px(110) : root.appThemeItem.px(155)
                            implicitHeight: root.appThemeItem.px(34)
                            color: root.currentViewMode === "NEXT" ? root.appThemeItem.bgItemActive : root.appThemeItem.bgItemDefault
                            border.color: root.currentViewMode === "NEXT" ? root.appThemeItem.borderActive : root.appThemeItem.borderDefault
                            border.width: 1
                            radius: root.appThemeItem.px(8)
                        }
                        onClicked: root.currentViewMode = "NEXT"
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    visible: root.effectiveWidth >= (root.appThemeItem ? root.appThemeItem.px(480) : 480)
                    text: root.isCompactHeader ? "TAB  |  ESC" : "TAB: Alternar  |  E / ESC: Volver"
                    color: root.appThemeItem.textDesc
                    font.pointSize: root.appThemeItem.pt(10)
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.minimumWidth: 0
                }

            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: root.appThemeItem.borderDefault
            }

            ListView {
                id: overlayListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.channelModel
                clip: true
                spacing: root.appThemeItem.px(10)
                boundsBehavior: Flickable.StopAtBounds
                focus: true
                rightMargin: root.appThemeItem.px(12)

                delegate: EpgGridDelegate {
                    width: overlayListView.width - overlayListView.rightMargin
                    channelModel: root.channelModel
                    currentChannelIndex: root.currentChannelIndex
                    viewMode: root.currentViewMode
                    onClicked: root.channelSelected(itemIndex)
                    appThemeItem: root.appThemeItem
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 5
                        radius: 3
                        color: root.appThemeItem.borderHover
                    }
                }
            }
        }
    }
}
