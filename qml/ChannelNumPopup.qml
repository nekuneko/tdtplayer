// ChannelNumPopup.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    anchors.centerIn: parent
    width: 240
    height: 140
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    signal numberAccepted(string numberStr)

    function openWithText(initialText) {
        root.open();
        numInputField.text = initialText;
        numInputField.forceActiveFocus();
    }

    background: Rectangle {
        color: "#1E293B"
        border.color: "#3B82F6"
        border.width: 2
        radius: 12
    }

    onOpened: numInputField.forceActiveFocus();
    onClosed: numInputField.text = "";

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Text {
            text: "Ir al Canal:"
            color: "white"
            font.bold: true
            font.pointSize: 12
            Layout.alignment: Qt.AlignHCenter
        }

        TextField {
            id: numInputField
            Layout.fillWidth: true
            horizontalAlignment: TextInput.AlignHCenter
            font.pointSize: 18
            font.bold: true
            color: "white"
            placeholderText: "0"
            validator: RegularExpressionValidator { regularExpression: /[0-9]+/ }

            background: Rectangle {
                color: "#0F172A"
                radius: 6
                border.color: numInputField.activeFocus ? "#3B82F6" : "#475569"
            }

            Keys.onReturnPressed: {
                if (text.length > 0) root.numberAccepted(text);
                root.close();
            }
            Keys.onEnterPressed: {
                if (text.length > 0) root.numberAccepted(text);
                root.close();
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                text: "Cancelar"
                Layout.fillWidth: true
                onClicked: root.close()
                background: Rectangle { color: "#475569"; radius: 6 }
                contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter }
            }

            Button {
                text: "Aceptar"
                Layout.fillWidth: true
                onClicked: {
                    if (numInputField.text.length > 0) root.numberAccepted(numInputField.text);
                    root.close();
                }
                background: Rectangle { color: "#3B82F6"; radius: 6 }
                contentItem: Text { text: parent.text; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
            }
        }
    }
}
