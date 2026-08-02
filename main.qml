// main.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import "qml"

ApplicationWindow {
    id: window
    width: 1024; height: 768; visible: true
    title: "Tvheadend Native Player"

    // Orquestador lógico de la aplicación
    PlaybackController {
        id: ctrl
        model: channelModel
        mediaPlayer: playerView.mediaPlayer // Apunta al reproductor modular
        sidebar: sidebar
        epgDrawer: epgDrawer
        onChannelZappedByKeyboard: if (isFullScreen) { epgDrawer.epgForceOpen = true; keyboardEpgTimer.restart() }
    }

    // Capturador de teclado
    KeyboardHandler {
        id: globalKeyboardHandler
        controller: ctrl; window: window; channelNumPopup: channelNumPopup; focus: true
    }

    FocusScope {
        id: mainFocusScope
        anchors.fill: parent

        // 📺 Sub-vista modularizada del reproductor de vídeo
        VideoPlayerView {
            id: playerView
            window: window
            controller: ctrl
            sidebarItem: sidebar
            epgDrawerItem: epgDrawer
            configSidebarItem: configSidebar
            globalKeyboardHandlerItem: globalKeyboardHandler

            // SOLUClÓN: Los anclajes adaptativos se calculan aquí, donde SÍ son hermanos del sidebar y epgDrawer
            anchors.left: parent.left
            anchors.right: (sidebar.visible && !ctrl.isFullScreen) ? sidebar.left : parent.right
            anchors.top: parent.top
            anchors.bottom: (epgDrawer.visible && !ctrl.isFullScreen) ? epgDrawer.top : parent.bottom
        }

        EpgDrawer {
            id: epgDrawer
            channelName: ctrl.osdChannelName; channelNo: ctrl.osdChannelNo; hoveredChannelName: ctrl.osdHoveredChannelName
            epgTitle: ctrl.epgTitle; epgDescription: ctrl.epgDescription; isFullScreen: ctrl.isFullScreen; sidebarItem: sidebar; z: 1 
            visible: !ctrl.isConfigMenuOpen && (!ctrl.isFullScreen || epgDrawer.epgForceOpen)

            Timer { id: keyboardEpgTimer; interval: 3000; onTriggered: epgDrawer.epgForceOpen = false }
        }

        ChannelSidebar {
            id: sidebar
            model: channelModel; currentChannelIndex: ctrl.currentChannelIndex; isFullScreen: ctrl.isFullScreen
            visible: !ctrl.isConfigMenuOpen && (!ctrl.isFullScreen || sidebar.sidebarForceOpen)
            
            onChannelSelected: (realIndex) => { ctrl.playChannel(realIndex); globalKeyboardHandler.forceActiveFocus() }
            
            onChannelHovered: (name) => {
                if (ctrl.zappingTimer.running) return
                ctrl.osdHoveredChannelName = name
                var epgData = channelModel.fetch_current_epg(name)
                if (epgData && epgData.title !== undefined) { ctrl.epgTitle = epgData.title; ctrl.epgDescription = epgData.description }
                if (ctrl.isFullScreen) epgDrawer.epgForceOpen = true
            }
            
            onExited: {
                if (ctrl.isFullScreen) { sidebar.sidebarForceOpen = false; epgDrawer.epgForceOpen = false; sidebar.forceCenterScrollSync() }
                ctrl.osdHoveredChannelName = ""
                var currentEpg = channelModel.fetch_current_epg(ctrl.osdChannelName)
                if (currentEpg && currentEpg.title !== undefined) { ctrl.epgTitle = currentEpg.title; ctrl.epgDescription = currentEpg.description }
                globalKeyboardHandler.forceActiveFocus()
            }
        }

        ConfigSidebar {
            id: configSidebar
            isFullScreen: ctrl.isFullScreen
            onImportRequested: fileDialog.open()
            onMouseExitedSidebar: ctrl.restorePanelsAfterConfig()
        }
    } 

    ChannelNumPopup {
        id: channelNumPopup
        onNumberAccepted: (numberStr) => ctrl.playChannelByNumber(numberStr)
    }

    Component.onCompleted: fileDialog.open()

    Timer {
        id: initScrollTimer
        interval: 100
        onTriggered: {
            var c = channelModel.rowCount()
            if (c > 0) { 
                sidebar.positionListView(500000 - (500000 % c), ListView.Beginning) 
                playerView.mediaPlayer.audioOutput.volume = 1.0; ctrl.currentVolumePercent = 100; ctrl.playChannel(0) 
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Carga tu lista Tvheadend"
        nameFilters: ["Archivos M3U (*.m3u *.m3u8)"]
        onAccepted: {
            var request = new XMLHttpRequest()
            request.open("GET", fileDialog.selectedFile, true)
            request.onreadystatechange = function() {
                if (request.readyState === XMLHttpRequest.DONE) {
                    channelModel.parse_m3u_content(request.responseText)
                    initScrollTimer.restart()
                }
            }
            request.send(null)
        }
    }
}
