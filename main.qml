// main.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import QtQuick.Dialogs

ApplicationWindow {
    id: window
    width: 1024
    height: 768
    visible: true
    title: "Tvheadend Native Player"

    property int currentChannelIndex: 0
    property bool isFullScreen: false
    property bool isVoluntarilyStopped: false
    
    property string osdChannelName: ""
    property string osdChannelLogo: ""
    property string osdChannelNo: ""

    // Función de sintonización circular infinita
    function playChannel(index) {
        if (channelModel.rowCount() === 0) return;
        
        if (index < 0) index = channelModel.rowCount() - 1;
        else if (index >= channelModel.rowCount()) index = 0;
        
        currentChannelIndex = index;
        isVoluntarilyStopped = false;
        
        osdChannelName = channelModel.data(channelModel.index(index, 0), Qt.UserRole + 1);
        osdChannelLogo = channelModel.data(channelModel.index(index, 0), Qt.UserRole + 3);
        osdChannelNo = channelModel.data(channelModel.index(index, 0), Qt.UserRole + 4);
        
        osdTimer.restart();
        osdPanel.opacity = 1.0;

        mediaPlayer.source = channelModel.get_url_at(index);
        mediaPlayer.play();
    }

    // Sintonizador directo buscando el CH del canal
    function playChannelByNumber(numberStr) {
        var count = channelModel.rowCount();
        for (var i = 0; i < count; i++) {
            if (channelModel.data(channelModel.index(i, 0), Qt.UserRole + 4) === numberStr) {
                window.playChannel(i);
                return;
            }
        }
        var targetIndex = parseInt(numberStr) - 1;
        if (!isNaN(targetIndex) && targetIndex >= 0 && targetIndex < count) {
            window.playChannel(targetIndex);
        }
    }

    Timer {
        id: osdTimer
        interval: 3000
        running: false
        repeat: false
        onTriggered: osdPanel.opacity = 0.0
    }

    // Capturador de teclado blindado en la raíz (Soluciona el marcado numérico)
    Item {
        anchors.fill: parent
        focus: true
        
        Keys.onUpPressed: window.playChannel(window.currentChannelIndex - 1)
        Keys.onDownPressed: window.playChannel(window.currentChannelIndex + 1)
        Keys.onLeftPressed: window.playChannel(window.currentChannelIndex - 1)
        Keys.onRightPressed: window.playChannel(window.currentChannelIndex + 1)
        
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Space) {
                if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                    window.isVoluntarilyStopped = true;
                    mediaPlayer.stop();
                } else {
                    window.isVoluntarilyStopped = false;
                    mediaPlayer.play();
                }
                event.accepted = true;
            }
            else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && mediaPlayer.playbackState !== MediaPlayer.PlayingState && !channelNumPopup.opened) {
                window.isVoluntarilyStopped = false;
                mediaPlayer.play();
                event.accepted = true;
            }
            else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9 && !channelNumPopup.opened) {
                channelNumPopup.open();
                numInputField.text = event.text;
                numInputField.forceActiveFocus();
                event.accepted = true;
            }
            else if (event.key === Qt.Key_Escape && window.isFullScreen && !channelNumPopup.opened) {
                if (sidebar.sidebarForceOpen) {
                    sidebar.sidebarForceOpen = false;
                } else {
                    window.visibility = Window.Windowed;
                    window.isFullScreen = false;
                }
                event.accepted = true;
            }
        }
    }

    FocusScope {
        id: mainFocusScope
        anchors.fill: parent

        MediaPlayer {
            id: mediaPlayer
            audioOutput: AudioOutput {}
            videoOutput: videoOutput
        }
        // Capa 1: El Reproductor de Vídeo (Ocupa siempre toda la pantalla o ventana)
        Rectangle {
            id: videoContainer
            anchors.left: parent.left
            anchors.right: (sidebar.visible && !window.isFullScreen) ? sidebar.left : parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: "black"

            VideoOutput {
                id: videoOutput
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectFit

                TapHandler {
                    onDoubleTapped: {
                        if (window.isFullScreen) {
                            window.visibility = Window.Windowed;
                            window.isFullScreen = false;
                        } else {
                            window.visibility = Window.FullScreen;
                            window.isFullScreen = true;
                        }
                    }
                }
                
                // Zona interactiva en el borde derecho: Hover en pantalla completa
                MouseArea {
                    id: rightEdgeSwipeArea
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: window.isFullScreen ? 50 : 0 
                    hoverEnabled: true
                    
                    onEntered: {
                        if (window.isFullScreen) {
                            sidebar.sidebarForceOpen = true
                        }
                    }
                }

                // Zona invisible sobre el vídeo para cerrar el menú haciendo clic fuera
                MouseArea {
                    anchors.fill: parent
                    anchors.rightMargin: sidebar.width
                    visible: window.isFullScreen && sidebar.sidebarForceOpen
                    onClicked: sidebar.sidebarForceOpen = false
                }

                // Cartel de fondo para estados de pausa o buffer
                Text {
                    anchors.centerIn: parent
                    text: window.isVoluntarilyStopped 
                          ? "Stream Detenido\nPulse Espacio o Enter para reanudar" 
                          : "Sintonizando canal...\nCargando flujo de Tvheadend"
                    color: window.isVoluntarilyStopped ? "#94A3B8" : "#3B82F6"
                    font.pointSize: window.isFullScreen ? 18 : 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.3
                    visible: mediaPlayer.playbackState !== MediaPlayer.PlayingState
                }
                
                // Panel flotante del OSD (CORREGIDO: Eliminado maxHeight problemático)
                Rectangle {
                    id: osdPanel
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: window.isFullScreen ? 40 : 20
                    width: parent.width * 0.8 
                    height: 85
                    radius: 12
                    color: "#1E293B" 
                    border.color: "#3B82F6" 
                    border.width: 1.5
                    opacity: 0.0 
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 300 }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 20

                        Image {
                            source: window.osdChannelLogo !== "" ? window.osdChannelLogo : ""
                            sourceSize.width: 55
                            sourceSize.height: 55
                            Layout.preferredWidth: 55
                            Layout.preferredHeight: 55
                            fillMode: Image.PreserveAspectFit
                            onStatusChanged: {
                                if (status === Image.Error) {
                                    source = "image://theme/media-playback-start"
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: window.osdChannelName
                                color: "white"
                                font.bold: true
                                font.pointSize: 16
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: window.osdChannelNo !== "" ? "Canal Informativo • CH " + window.osdChannelNo : "Tvheadend Stream"
                                color: "#94A3B8"
                                font.pointSize: 10
                            }
                        }
                    }
                } // Fin de osdPanel
            } // Fin de VideoOutput
        } // Fin de videoContainer
        
        // Capa 2: El Panel Lateral de Canales (CORREGIDO: Convertido a MouseArea para soportar onExited nativo)
        MouseArea {
            id: sidebar
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            
            property bool sidebarForceOpen: false
            visible: !window.isFullScreen || sidebarForceOpen
            width: visible ? 290 : 0

            // Habilitamos el hover nativo en la raíz del panel
            hoverEnabled: true

            // Al ser un MouseArea, esto ahora es 100% legal y funciona sin romper la app
            onExited: {
                if (window.isFullScreen) {
                    sidebarForceOpen = false
                }
            }

            // Dibujamos el fondo oscuro premium usando un Rectangle interno
            Rectangle {
                anchors.fill: parent
                color: "#111827"
            }

            Behavior on width {
                NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
            }

            ListView {
                id: channelListView
                anchors.fill: parent
                model: channelModel
                clip: true

                delegate: ItemDelegate {
                    width: 290
                    height: 60
                    highlighted: window.currentChannelIndex === index

                    background: Rectangle {
                        color: window.currentChannelIndex === index ? "#1E3A8A" : "transparent"
                        opacity: 0.3
                    }

                    contentItem: RowLayout {
                        width: 270
                        anchors.centerIn: parent
                        spacing: 12
                        
                        Image {
                            source: model.logo !== "" ? model.logo : ""
                            sourceSize.width: 35
                            sourceSize.height: 35
                            Layout.preferredWidth: 35
                            Layout.preferredHeight: 35
                            fillMode: Image.PreserveAspectFit
                            
                            onStatusChanged: {
                                if (status === Image.Error) {
                                    source = "image://theme/media-playback-start"
                                }
                            }
                        }

                        Text {
                            text: model.name
                            color: window.currentChannelIndex === index ? "#3B82F6" : "#E2E8F0"
                            font.bold: window.currentChannelIndex === index
                            font.pointSize: 11
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: model.chNo !== "" ? "CH " + model.chNo : ""
                            color: window.currentChannelIndex === index ? "#3B82F6" : "#64748B"
                            font.pointSize: 9
                        }
                    }

                    onClicked: {
                        window.playChannel(index)
                        sidebar.sidebarForceOpen = false 
                    }
                }
            }
        }
    } // Fin de mainFocusScope

    // POPUP MODAL: Marcador Numérico Inteligente
    Popup {
        id: channelNumPopup
        anchors.centerIn: parent
        width: 240
        height: 140
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#1E293B"
            border.color: "#3B82F6"
            border.width: 2
            radius: 12
        }

        onOpened: {
            numInputField.forceActiveFocus();
        }
        
        onClosed: {
            numInputField.text = "";
        }

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
                    if (text.length > 0) {
                        window.playChannelByNumber(text);
                    }
                    channelNumPopup.close();
                }
                Keys.onEnterPressed: {
                    if (text.length > 0) {
                        window.playChannelByNumber(text);
                    }
                    channelNumPopup.close();
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Button {
                    text: "Cancelar"
                    Layout.fillWidth: true
                    onClicked: channelNumPopup.close()
                    
                    background: Rectangle {
                        color: "#475569"
                        radius: 6
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Button {
                    text: "Aceptar"
                    Layout.fillWidth: true
                    onClicked: {
                        if (numInputField.text.length > 0) {
                            window.playChannelByNumber(numInputField.text);
                        }
                        channelNumPopup.close();
                    }

                    background: Rectangle {
                        color: "#3B82F6"
                        radius: 6
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        fileDialog.open()
    }

    FileDialog {
        id: fileDialog
        title: "Carga tu lista Tvheadend"
        nameFilters: ["Archivos M3U (*.m3u *.m3u8)"]
        onAccepted: {
            var request = new XMLHttpRequest();
            request.open("GET", fileDialog.selectedFile, false);
            request.send(null);
            channelModel.parse_m3u_content(request.responseText);
            window.playChannel(0);
        }
    }
}

