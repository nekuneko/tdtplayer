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

    function playChannel(index) {
        if (channelModel.rowCount() === 0) return;
        
        if (index < 0) index = channelModel.rowCount() - 1;
        else if (index >= channelModel.rowCount()) index = 0;
        
        currentChannelIndex = index;
        isVoluntarilyStopped = false;
        
        // Lee los metadatos del canal sintonizado desde tu modelo de Python
        osdChannelName = channelModel.data(channelModel.index(index, 0), Qt.UserRole + 1);
        osdChannelLogo = channelModel.data(channelModel.index(index, 0), Qt.UserRole + 3);
        osdChannelNo = channelModel.data(channelModel.index(index, 0), Qt.UserRole + 4);
        
        // Muestra el panel y reinicia la cuenta atrás de 3 segundos
        osdTimer.restart();
        osdPanel.opacity = 1.0;

        mediaPlayer.source = channelModel.get_url_at(index);
        mediaPlayer.play();
    }

    // Lógica para sintonizar el canal buscando por su número de canal (CH)
    function playChannelByNumber(numberStr) {
        var count = channelModel.rowCount();
        for (var i = 0; i < count; i++) {
            // El modelo expone chNo. Comparamos cadenas limpias
            if (channelModel.data(channelModel.index(i, 0), Qt.UserRole + 4) === numberStr) {
                window.playChannel(i);
                return;
            }
        }
        // Si no encuentra el número exacto, opcionalmente puedes sintonizar por el índice directo del índice (i + 1)
        var targetIndex = parseInt(numberStr) - 1;
        if (!isNaN(targetIndex) && targetIndex >= 0 && targetIndex < count) {
            window.playChannel(targetIndex);
        }
    }

    // Capturador de eventos de teclado global
    Item {
        focus: true
        Keys.onUpPressed: window.playChannel(window.currentChannelIndex - 1)
        Keys.onDownPressed: window.playChannel(window.currentChannelIndex + 1)
        Keys.onLeftPressed: window.playChannel(window.currentChannelIndex - 1)
        Keys.onRightPressed: window.playChannel(window.currentChannelIndex + 1)
        
        Keys.onPressed: (event) => {
            // ACTUALIZADO: Control de la barra espaciadora gestionando la bandera voluntaria
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
            // ACTUALIZADO: Enter también apaga la bandera voluntaria al reanudar
            else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && mediaPlayer.playbackState !== MediaPlayer.PlayingState && !channelNumPopup.opened) {
                window.isVoluntarilyStopped = false;
                mediaPlayer.play();
                event.accepted = true;
            }
            // Marcador numérico (0-9)
            else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9 && !channelNumPopup.opened) {
                channelNumPopup.open();
                numInputField.text = event.text;
                numInputField.forceActiveFocus();
                event.accepted = true;
            }
            // Control de escape para pantalla completa
            else if (event.key === Qt.Key_Escape && window.isFullScreen && !channelNumPopup.opened) {
                window.visibility = Window.Windowed;
                window.isFullScreen = false;
                event.accepted = true;
            }
        }
    }

    MediaPlayer {
        id: mediaPlayer
        audioOutput: AudioOutput {}
        videoOutput: videoOutput
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
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
                
                // NUEVO: Cartel de fondo que aparece SOLO cuando el stream no se está reproduciendo
                                // ACTUALIZADO: Texto dinámico que distingue entre detención voluntaria y sintonización de buffer
                Text {
                    anchors.centerIn: parent
                    text: window.isVoluntarilyStopped 
                          ? "Stream Detenido\nPulse Espacio o Enter para reanudar" 
                          : "Sintonizando canal...\nCargando flujo de Tvheadend"
                    color: window.isVoluntarilyStopped ? "#94A3B8" : "#3B82F6" // Gris para detenido, azul eléctrico para carga
                    font.pointSize: window.isFullScreen ? 18 : 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.3
                    
                    // Visible si el reproductor no está reproduciendo activamente (parado, cargando o en error)
                    visible: mediaPlayer.playbackState !== MediaPlayer.PlayingState
                }


                
                // NUEVO: El banner translúcido inferior del OSD
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
                } // Fin del Rectangle osdPanel
            } // Fin de VideoOutput

        }

        Rectangle {
            id: sidebar
            Layout.preferredWidth: 290
            Layout.fillHeight: true
            color: "#111827"
            visible: !window.isFullScreen

            ListView {
                id: channelListView
                anchors.fill: parent
                model: channelModel
                clip: true

                delegate: ItemDelegate {
                    width: parent.width
                    height: 60
                    highlighted: window.currentChannelIndex === index

                    background: Rectangle {
                        color: window.currentChannelIndex === index ? "#1E3A8A" : "transparent"
                        opacity: 0.3
                    }

                    contentItem: RowLayout {
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

                    onClicked: window.playChannel(index)
                }
            }
        }
    }

    // POPUP FLOTANTE: Marcador Numérico Inteligente
    Popup {
        id: channelNumPopup
        anchors.centerIn: parent
        width: 240
        height: 140
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#1E293B" // Slate 800 premium
            border.color: "#3B82F6" // Borde azul corporativo
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
                
                // Restringe la entrada a solo números
                validator: RegularExpressionValidator { regularExpression: /[0-9]+/ }

                background: Rectangle {
                    color: "#0F172A"
                    radius: 6
                    border.color: numInputField.activeFocus ? "#3B82F6" : "#475569"
                }

                // Al pulsar Enter en el popup, sintoniza y se cierra
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

    // NUEVO: Temporizador invisible de 3 segundos que oculta el panel al terminar
    Timer {
        id: osdTimer
        interval: 3000
        running: false
        repeat: false
        onTriggered: osdPanel.opacity = 0.0
    }

    FileDialog {
        id: fileDialog
        title: "Carga tu lista Tvheadend"
        nameFilters: ["Archivos M3U (*.m3u *.m3u8)"]
        onAccepted: {
            var request = new XMLHttpRequest();
            request.open("GET", fileDialog.selectedFile, false);
            request.send(null);
            
            // 1. Procesa y rellena la lista de canales en Python
            channelModel.parse_m3u_content(request.responseText);
            
            // 2. Fuerza el foco global en la vista para recibir las teclas
            channelListView.forceActiveFocus();
            
            // 3. Sintoniza y reproduce el primer canal (Índice 0) de inmediato
            window.playChannel(0);
        }
    }


       

}
