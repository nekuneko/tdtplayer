// qml/ChannelSidebarScrollTrack.qml
import QtQuick

Item {
    id: root

    required property int realCount
    required property int visibleRows
    required property real currentPos
    required property var appThemeItem

    signal scrubRequested(int targetIndex)

    readonly property bool isDragging: scrollbarDragArea.pressed

    function px(v) { return root.appThemeItem ? root.appThemeItem.px(v) : v; }

    readonly property real progress: {
        if (root.realCount <= 1)
            return 0.0;
        var norm = ((root.currentPos % root.realCount) + root.realCount) % root.realCount;
        return Math.max(0.0, Math.min(1.0, norm / (root.realCount - 1)));
    }

    visible: root.realCount > root.visibleRows
    width: px(8)

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.px(3)
        radius: width / 2
        color: Qt.rgba(1, 1, 1, 0.15)
    }

    Rectangle {
        id: scrollThumb
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.px(4)
        radius: width / 2
        height: Math.max(root.px(30), parent.height * Math.min(1.0, root.visibleRows / Math.max(1, root.realCount)))
        y: (parent.height - height) * root.progress
        color: "#FFFFFF"
        opacity: (scrollbarDragArea.pressed || scrollbarDragArea.containsMouse) ? 1.0 : 0.8

        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        id: scrollbarDragArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function scrubToY(mouseY) {
            if (root.realCount <= 0)
                return;
            var usable = Math.max(1, root.height - scrollThumb.height);
            var clamped = Math.max(0, Math.min(usable, mouseY - scrollThumb.height * 0.5));
            var targetIdx = Math.min(root.realCount - 1, Math.floor((clamped / usable) * root.realCount));
            root.scrubRequested(targetIdx);
        }

        onPressed: mouse => scrubToY(mouse.y)
        onPositionChanged: mouse => { if (pressed) scrubToY(mouse.y); }
    }
}
