// qml/EpgDrawer.qml
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string channelName: ""
    property string channelNo: ""
    property string hoveredChannelName: ""
    property string channelLogo: ""
    property string epgTitle: ""
    property string epgDescription: ""
    property bool isFullScreen: false
    property var sidebarItem: null
    property bool epgForceOpen: false

    readonly property bool containsMouse: epgMouseTracker.containsMouse

    height: root.isFullScreen ? (appTheme ? appTheme.px(180) : 180) : (appTheme ? appTheme.px(160) : 160)

    anchors.bottom: parent ? parent.bottom : undefined
    anchors.left: parent ? parent.left : undefined

    color: appTheme.bgAbsolute
    opacity: 0.98
    border.color: appTheme.borderActive
    border.width: root.isFullScreen ? 1.5 : 0

    Behavior on height {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutQuad
        }
    }

    Timer {
        id: safetyExitTimer
        interval: 200
        running: false
        repeat: false
        onTriggered: root.epgForceOpen = false
    }

    MouseArea {
        id: epgMouseTracker
        anchors.fill: parent
        hoverEnabled: true
        z: -1
        cursorShape: Qt.ArrowCursor
        onEntered: safetyExitTimer.stop()
        onExited: safetyExitTimer.start()
        onPositionChanged: if (typeof playerView !== "undefined")
            playerView.resetMouseCursor()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: appTheme ? appTheme.px(16) : 16
        spacing: appTheme ? appTheme.px(10) : 10

        EpgHeaderRow {
            id: innerHeaderRow
            isFullScreen: root.isFullScreen
            channelNo: root.channelNo
            channelName: root.channelName
            hoveredChannelName: root.hoveredChannelName

            // 🚀 ASIGNACIÓN DINÁMICA DE ENLACE REEL:
            Component.onCompleted: {
                innerHeaderRow.epgTitle = Qt.binding(function () {
                    return root.epgTitle;
                });
            }
        }

        // 🚀 CORRECCIÓN DE LAYOUT: Cambiado 'height: 1' por 'Layout.preferredHeight: 1' para evitar el comportamiento indefinido
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: appTheme.borderDefault
        }

        EpgProgramContent {
            isFullScreen: root.isFullScreen
            channelLogo: root.channelLogo
            epgTitle: root.epgTitle
            epgDescription: root.epgDescription
        }
    }

    WheelHandler {
        id: drawerVolumeWheel
        orientation: Qt.Vertical
        onWheel: event => {
            if (event.angleDelta.y > 0)
                ctrl.changeVolume(5);
            else if (event.angleDelta.y < 0)
                ctrl.changeVolume(-5);
        }
    }
}
