// qml/ChannelNumPopup.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    anchors.centerIn: parent

    readonly property bool isMiniMode: parent ? (parent.width < (appTheme ? appTheme.px(380) : 380) || parent.height < (appTheme ? appTheme.px(250) : 250)) : false

    width: isMiniMode
           ? Math.min(parent ? parent.width - 24 : 220, appTheme ? appTheme.px(220) : 220)
           : Math.min(parent ? parent.width - 32 : 270, appTheme ? appTheme.px(270) : 270)
    height: isMiniMode
            ? (appTheme ? appTheme.px(56) : 56)
            : (appTheme ? appTheme.px(156) : 156)

    modal: true
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    signal numberAccepted(string numberStr)

    function openWithText(initialText) {
        root.open();
        numInputField.text = initialText;
        numInputField.forceActiveFocus();
    }

    Overlay.modal: Rectangle {
        color: Qt.alpha("#000000", 0.45)
    }

    background: Rectangle {
        color: appTheme ? appTheme.bgAbsolute : "#0B0F17"
        border.color: appTheme ? appTheme.borderActive : "#60A5FA"
        border.width: 1.5
        radius: root.isMiniMode
                ? (appTheme ? appTheme.px(12) : 12)
                : (appTheme ? appTheme.px(16) : 16)
    }

    onOpened: numInputField.forceActiveFocus()
    onClosed: numInputField.text = ""

    // Modo compacto para PiP o ventanas muy pequeñas
    RowLayout {
        visible: root.isMiniMode
        anchors.fill: parent
        anchors.leftMargin: appTheme ? appTheme.px(12) : 12
        anchors.rightMargin: appTheme ? appTheme.px(8) : 8
        spacing: appTheme ? appTheme.px(8) : 8

        Text {
            text: "Canal"
            color: appTheme ? appTheme.textDesc : "#CBD5E1"
            font.bold: true
            font.pointSize: appTheme ? appTheme.pt(10) : 10
            renderType: Text.NativeRendering
            Layout.alignment: Qt.AlignVCenter
        }

        TextField {
            id: miniNumField
            visible: root.isMiniMode
            text: numInputField.text
            onTextEdited: numInputField.text = text
            Layout.fillWidth: true
            Layout.preferredHeight: appTheme ? appTheme.px(36) : 36
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            font.pointSize: appTheme ? appTheme.pt(13) : 13
            font.bold: true
            color: appTheme ? appTheme.textTitle : "#FFFFFF"
            placeholderText: "0"
            validator: RegularExpressionValidator {
                regularExpression: /[0-9]+/
            }
            background: Rectangle {
                color: appTheme ? appTheme.bgItemDefault : "#0B0F19"
                radius: appTheme ? appTheme.px(8) : 8
                border.color: appTheme ? appTheme.borderActive : "#60A5FA"
                border.width: 1
            }
            Keys.onReturnPressed: {
                if (text.length > 0)
                    root.numberAccepted(text);
                root.close();
            }
            Keys.onEnterPressed: {
                if (text.length > 0)
                    root.numberAccepted(text);
                root.close();
            }
        }

        Button {
            id: miniAcceptBtn
            text: "➔"
            Layout.preferredWidth: appTheme ? appTheme.px(36) : 36
            Layout.preferredHeight: appTheme ? appTheme.px(36) : 36
            onClicked: {
                if (numInputField.text.length > 0)
                    root.numberAccepted(numInputField.text);
                root.close();
            }
            background: Rectangle {
                color: appTheme ? appTheme.bgItemActive : "#1D4ED8"
                radius: appTheme ? appTheme.px(8) : 8
            }
            contentItem: Text {
                text: miniAcceptBtn.text
                color: appTheme ? appTheme.getW3cContrast(appTheme.bgItemActive) : "#FFFFFF"
                font.bold: true
                font.pointSize: appTheme ? appTheme.pt(11) : 11
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    // Modo estándar (tarjeta flotante estilo icono)
    ColumnLayout {
        visible: !root.isMiniMode
        anchors.fill: parent
        anchors.margins: appTheme ? appTheme.px(16) : 16
        spacing: appTheme ? appTheme.px(12) : 12

        Text {
            text: "Ir al Canal"
            color: appTheme ? appTheme.textTitle : "#FFFFFF"
            font.bold: true
            font.pointSize: appTheme ? appTheme.pt(11.5) : 11.5
            renderType: Text.NativeRendering
            Layout.alignment: Qt.AlignHCenter
        }

        TextField {
            id: numInputField
            Layout.fillWidth: true
            Layout.preferredHeight: appTheme ? appTheme.px(44) : 44
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            font.pointSize: appTheme ? appTheme.pt(17) : 17
            font.bold: true
            color: appTheme ? appTheme.textTitle : "#FFFFFF"
            placeholderText: "0"
            validator: RegularExpressionValidator {
                regularExpression: /[0-9]+/
            }

            background: Rectangle {
                color: appTheme ? appTheme.bgItemDefault : "#0B0F19"
                radius: appTheme ? appTheme.px(10) : 10
                border.color: numInputField.activeFocus
                              ? (appTheme ? appTheme.borderActive : "#60A5FA")
                              : (appTheme ? appTheme.borderDefault : "#1E293B")
                border.width: 1
            }

            Keys.onReturnPressed: {
                if (text.length > 0)
                    root.numberAccepted(text);
                root.close();
            }
            Keys.onEnterPressed: {
                if (text.length > 0)
                    root.numberAccepted(text);
                root.close();
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: appTheme ? appTheme.px(10) : 10

            Button {
                // 🚀 ID EXPLÍCITO: Asignamos un identificador unívoco al botón de cancelar
                id: cancelBtn
                text: "Cancelar"
                Layout.fillWidth: true
                Layout.preferredHeight: appTheme ? appTheme.px(34) : 34
                onClicked: root.close()
                background: Rectangle {
                    color: cancelBtn.hovered
                           ? (appTheme ? appTheme.bgItemHover : "#1E293B")
                           : (appTheme ? appTheme.bgItemDefault : "#0B0F19")
                    border.color: appTheme ? appTheme.borderDefault : "#1E293B"
                    border.width: 1
                    radius: appTheme ? appTheme.px(8) : 8
                }

                // 🚀 VINCULACIÓN CUALIFICADA: Apuntamos directamente al ID del botón en lugar de parent
                contentItem: Text {
                    text: cancelBtn.text
                    color: appTheme ? appTheme.textDesc : "#CBD5E1"
                    font.pointSize: appTheme ? appTheme.pt(10) : 10
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                // 🚀 ID EXPLÍCITO: Asignamos un identificador unívoco al botón de aceptar
                id: acceptBtn
                text: "Aceptar"
                Layout.fillWidth: true
                Layout.preferredHeight: appTheme ? appTheme.px(34) : 34
                onClicked: {
                    if (numInputField.text.length > 0)
                        root.numberAccepted(numInputField.text);
                    root.close();
                }
                background: Rectangle {
                    color: appTheme ? appTheme.bgItemActive : "#1D4ED8"
                    border.color: appTheme ? appTheme.borderActive : "#60A5FA"
                    border.width: 1
                    radius: appTheme ? appTheme.px(8) : 8
                }

                // 🚀 VINCULACIÓN CUALIFICADA: Apuntamos directamente al ID del botón en lugar de parent
                contentItem: Text {
                    text: acceptBtn.text
                    color: appTheme ? appTheme.getW3cContrast(appTheme.bgItemActive) : "#FFFFFF"
                    font.bold: true
                    font.pointSize: appTheme ? appTheme.pt(10) : 10
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
