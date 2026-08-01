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

    function playChannel(index) {
        if (channelModel.rowCount() === 0) return;
        
        if (index < 0) index = channelModel.rowCount() - 1;
        else if (index >= channelModel.rowCount()) index = 0;
        
        currentChannelIndex = index;
        mediaPlayer.source = channelModel.get_url_at(index);
        mediaPlayer.play();
    }

    Item {
        focus: true
        Keys.onUpPressed: window.playChannel(window.currentChannelIndex - 1)
        Keys.onDownPressed: window.playChannel(window.currentChannelIndex + 1)
        Keys.onEscapePressed: {
            if (window.isFullScreen) {
                window.visibility = Window.Windowed;
                window.isFullScreen = false;
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
                // Fuerza al escalador de la GPU Intel a promediar los campos verticales (Filtro Anti-Entrelazado)
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
            }

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
