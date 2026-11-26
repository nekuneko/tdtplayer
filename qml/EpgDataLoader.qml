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

    signal fileSelectorOpenRequested

    Component.onCompleted: {
        if (root.appSettings.lastM3uUrl !== "") {
            root.loadM3uFromUrl(root.appSettings.lastM3uUrl, false);
        } else {
            fileDialog.open();
        }
    }

    onFileSelectorOpenRequested: fileDialog.open()

    function loadM3uFromUrl(url, isImport) {
        if (!url || url === "") {
            fileDialog.open();
            return;
        }

        var clearCache = Boolean(isImport);
        var request = new XMLHttpRequest();
        request.open("GET", url, true);
        request.onreadystatechange = function () {
            if (request.readyState === XMLHttpRequest.DONE) {
                var body = request.responseText || "";
                var isLocalFile = url.toString().indexOf("file:") === 0;
                var okStatus = (request.status === 200) || (isLocalFile && request.status === 0);

                if (okStatus && body.trim().length > 0) {
                    if (clearCache && root.playerView && root.playerView.mediaPlayer) {
                        root.playerView.mediaPlayer.stop();
                        root.playerView.mediaPlayer.source = "";
                    }
                    channelModel.parse_m3u_content(body, clearCache);
                    initScrollTimer.restart();
                } else {
                    console.log("No se pudo cargar M3U (" + url + ", status=" + request.status + "), abriendo selector...");
                    fileDialog.open();
                }
            }
        };
        request.send(null);
    }

    Timer {
        id: initScrollTimer
        interval: 100
        onTriggered: {
            var c = channelModel.rowCount();
            if (c > 0) {
                var savedIndex = root.appSettings.lastChannelIndex;
                if (savedIndex < 0 || savedIndex >= c) {
                    savedIndex = 0;
                }

                root.sidebar.positionListView(savedIndex, ListView.Center);
                if (root.playerView && root.playerView.mediaPlayer && root.playerView.mediaPlayer.audioOutput) {
                    root.playerView.mediaPlayer.audioOutput.volume = 1.0;
                }
                root.ctrl.currentVolumePercent = 100;
                root.ctrl.playChannel(savedIndex, true);
            } else {
                fileDialog.open();
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Carga tu lista Tvheadend"
        nameFilters: ["Archivos M3U (*.m3u *.m3u8)"]
        onAccepted: {
            var selected = fileDialog.selectedFile.toString();
            root.appSettings.lastM3uUrl = selected;
            root.loadM3uFromUrl(selected, true);
        }
    }
}
