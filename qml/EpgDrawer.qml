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
    readonly property real outerMargin: appTheme ? appTheme.px(12) : 12

    height: appTheme ? appTheme.px(160) : 160

    anchors.bottom: parent ? parent.bottom : undefined
    anchors.left: parent ? parent.left : undefined
    anchors.bottomMargin: outerMargin
    anchors.leftMargin: outerMargin

    color: appTheme.bgAbsolute
    opacity: 0.98
    radius: appTheme ? appTheme.px(16) : 16
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
            if (!epgHoverHandler.hovered) {
                root.epgForceOpen = false;
            }
        }
    }

    HoverHandler {
        id: epgHoverHandler
        margin: root.outerMargin
        onHoveredChanged: {
            if (hovered) {
                safetyExitTimer.stop();
                if (typeof playerView !== "undefined") {
                    playerView.resetMouseCursor();
                }
            } else {
                safetyExitTimer.restart();
            }
        }
        onPointChanged: {
            if (typeof playerView !== "undefined") {
                playerView.resetMouseCursor();
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        cursorShape: Qt.ArrowCursor
        onPressed: mouse => mouse.accepted = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: appTheme ? appTheme.px(16) : 16
        spacing: appTheme ? appTheme.px(10) : 10

        EpgHeaderRow {
            id: innerHeaderRow
            isFullScreen: false
            channelNo: root.channelNo
            channelName: root.channelName
            hoveredChannelName: root.hoveredChannelName

            Component.onCompleted: {
                innerHeaderRow.epgTitle = Qt.binding(function () {
                    return root.epgTitle;
                });
            }
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
            if (event.angleDelta.y > 0)
                ctrl.changeVolume(5);
            else if (event.angleDelta.y < 0)
                ctrl.changeVolume(-5);
        }
    }
}
