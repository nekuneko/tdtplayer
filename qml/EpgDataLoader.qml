// qml/EpgDataLoader.qml
import QtQuick
import QtQuick.Dialogs

Item {
    id: root

    required property var window
    required property var appSettings
    required property var playerView
    required property var ctrl
    required property var sidebar

    Component.onCompleted: {
        if (root.appSettings.lastM3uUrl !== "") {
            root.loadM3uFromUrl(root.appSettings.lastM3uUrl);
        } else {
            fileDialog.open();
        }
    }

    function loadM3uFromUrl(url) {
        var request = new XMLHttpRequest()
        request.open("GET", url, true)
        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request.status === 200 || request.status === 0) { 
                    channelModel.parse_m3u_content(request.responseText)
                    initScrollTimer.restart()
                } else {
                    console.log("Error al cargar el archivo persistente, abriendo selector de archivos.")
                    fileDialog.open()
                }
            }
        }
        request.send(null)
    }

    Timer {
        id: initScrollTimer
        interval: 100
        onTriggered: {
            var c = channelModel.rowCount()
            if (c > 0) { 
                var savedIndex = root.appSettings.lastChannelIndex
                if (savedIndex < 0 || savedIndex >= c) {
                    savedIndex = 0
                }
                
                root.sidebar.positionListView(500000 - (500000 % c) + savedIndex, ListView.Beginning) 
                root.playerView.mediaPlayer.audioOutput.volume = 1.0
                root.ctrl.currentVolumePercent = 100
                root.ctrl.playChannel(savedIndex) 
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Carga tu lista Tvheadend"
        nameFilters: ["Archivos M3U (*.m3u *.m3u8)"]
        onAccepted: {
            var selected = fileDialog.selectedFile.toString()
            root.appSettings.lastM3uUrl = selected 
            root.loadM3uFromUrl(selected)
        }
    }
}
