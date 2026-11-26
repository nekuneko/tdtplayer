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

    readonly property bool containsMouse: epgHoverHandler.hovered
    readonly property real outerMargin: px(12)

    function px(v) { return (typeof appTheme !== "undefined" && appTheme) ? appTheme.px(v) : v; }

    function notifyCursorActivity() {
        if (typeof playerView !== "undefined" && playerView) {
            playerView.resetMouseCursor();
        }
    }

    height: px(160)

    anchors.bottom: parent ? parent.bottom : undefined
    anchors.left: parent ? parent.left : undefined
    anchors.bottomMargin: outerMargin
    anchors.leftMargin: outerMargin

    color: appTheme.bgAbsolute
    opacity: 0.98
    radius: px(16)
    border.color: appTheme.borderDefault
    border.width: 1

    Behavior on height {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: safetyExitTimer
        interval: 350
        running: false
        repeat: false
        onTriggered: {
            var onSidebar = Boolean(root.sidebarItem && root.sidebarItem.containsMouse);
            if (!epgHoverHandler.hovered && !onSidebar) {
                root.epgForceOpen = false;
                if (typeof sidebarHoverSync !== "undefined") {
                    sidebarHoverSync.performFullClose();
                } else if (root.sidebarItem) {
                    root.sidebarItem.sidebarForceOpen = false;
                }
            }
        }
    }

    HoverHandler {
        id: epgHoverHandler
        margin: root.outerMargin
        onHoveredChanged: {
            if (hovered) {
                safetyExitTimer.stop();
                root.notifyCursorActivity();
            } else {
                safetyExitTimer.restart();
            }
        }
        onPointChanged: root.notifyCursorActivity()
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        cursorShape: Qt.ArrowCursor
        onPressed: mouse => mouse.accepted = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.px(16)
        spacing: root.px(10)

        EpgHeaderRow {
            id: innerHeaderRow
            isFullScreen: false
            channelNo: root.channelNo
            channelName: root.channelName
            hoveredChannelName: root.hoveredChannelName
            epgTitle: root.epgTitle
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: appTheme.borderDefault
        }

        EpgProgramContent {
            isFullScreen: false
            channelLogo: root.channelLogo
            epgTitle: root.epgTitle
            epgDescription: root.epgDescription
        }
    }

    WheelHandler {
        id: drawerVolumeWheel
        orientation: Qt.Vertical
        onWheel: event => {
            var step = event.angleDelta.y > 0 ? 5 : -5;
            ctrl.changeVolume(step);
        }
    }
}
