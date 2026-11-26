// qml/ChannelSidebar.qml
import QtQuick

MouseArea {
    id: root
    property var model
    property int currentChannelIndex: 0
    property bool isFullScreen: false
    property bool sidebarForceOpen: false
    property var appThemeItem: null

    signal channelSelected(int realIndex)
    signal channelHovered(string channelName)

    function px(v) { return root.appThemeItem ? root.appThemeItem.px(v) : v; }

    readonly property real outerMargin: px(12)
    readonly property real itemHeight: px(64)
    readonly property real itemSpacing: px(8)
    readonly property real rowStride: itemHeight + itemSpacing

    property int realCount: root.model ? root.model.rowCount() : 0

    Connections {
        target: root.model
        function onModelReset() { root.realCount = root.model ? root.model.rowCount() : 0; }
        function onRowsInserted() { root.realCount = root.model ? root.model.rowCount() : 0; }
        function onRowsRemoved() { root.realCount = root.model ? root.model.rowCount() : 0; }
    }

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: (parent ? Math.min(px(320), Math.max(px(195), parent.width * 0.44)) : px(320)) + outerMargin

    visible: root.sidebarForceOpen
    hoverEnabled: true
    layer.enabled: sidebarXAnimation.running
    layer.smooth: false
    x: (root.visible && root.sidebarForceOpen) ? (parent.width - width) : parent.width

    function refreshEpg() {
        if (root.model && root.model.refresh_sidebar_epg) {
            root.model.refresh_sidebar_epg();
        }
    }

    onVisibleChanged: {
        if (visible)
            root.refreshEpg();
    }

    onSidebarForceOpenChanged: {
        if (sidebarForceOpen) {
            root.forceCenterScrollSync();
            root.refreshEpg();
        } else if (typeof ctrl !== "undefined") {
            ctrl.cancelPendingZapping();
        }
    }

    Timer {
        id: sidebarEpgRefreshTimer
        interval: 15000
        running: root.visible
        repeat: true
        onTriggered: root.refreshEpg()
    }

    Behavior on x {
        NumberAnimation {
            id: sidebarXAnimation
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    function visibleRowsCount() {
        return Math.max(1, Math.floor(channelPathView.height / Math.max(1, root.rowStride)));
    }

    function jumpToIndex(index, mode) {
        if (!sidebarXAnimation.running && root.model && index >= 0 && index < root.realCount) {
            offsetAnim.stop();
            channelPathView.positionViewAtIndex(index, mode);
        }
    }

    function positionListView(index, mode) { root.jumpToIndex(index, PathView.Center); }
    function forceKeyboardScrollSync() { root.jumpToIndex(root.currentChannelIndex, PathView.Contain); }
    function forceCenterScrollSync() { root.jumpToIndex(root.currentChannelIndex, PathView.Center); }

    function getCurrentScrollIndex() {
        if (root.realCount <= 0)
            return -1;
        var idx = Math.round(root.realCount - channelPathView.offset) % root.realCount;
        return (idx + root.realCount) % root.realCount;
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: root.outerMargin
        color: root.appThemeItem.bgAbsolute
        radius: root.px(16)
        border.color: root.appThemeItem.borderDefault
        border.width: 1
    }

    PathView {
        id: channelPathView
        anchors.fill: parent
        anchors.margins: root.outerMargin + root.px(10)
        clip: true
        model: root.model

        readonly property int visibleSlots: Math.max(3, Math.ceil(height / Math.max(1, root.rowStride)) + 2)
        readonly property real centerSlot: (pathItemCount - 1) * 0.5
        pathItemCount: root.realCount > 0 ? Math.min(root.realCount, visibleSlots) : 0

        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.NoHighlightRange
        snapMode: PathView.NoSnap
        interactive: true

        NumberAnimation {
            id: offsetAnim
            target: channelPathView
            property: "offset"
            duration: 180
            easing.type: Easing.OutCubic
        }

        path: Path {
            startX: channelPathView.width * 0.5
            startY: -root.rowStride * 0.5
            PathLine {
                x: channelPathView.width * 0.5
                y: -root.rowStride * 0.5 + (Math.max(1, channelPathView.pathItemCount - 1) * root.rowStride)
            }
        }

        WheelHandler {
            id: sidebarExploreWheel
            orientation: Qt.Vertical
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

            property real wheelBoost: 1.0
            property real lastWheelTime: 0
            property int lastWheelDir: 0
            property real targetOffset: 0

            onWheel: event => {
                if (root.realCount === 0)
                    return;

                var now = Date.now();
                var dir = event.angleDelta.y > 0 ? 1 : -1;

                if ((now - lastWheelTime) < 180 && dir === lastWheelDir) {
                    wheelBoost = Math.min(2.6, wheelBoost + 0.28);
                } else {
                    wheelBoost = 1.0;
                }
                lastWheelTime = now;
                lastWheelDir = dir;

                var current = channelPathView.offset;
                if (!offsetAnim.running) {
                    targetOffset = current;
                } else {
                    var cycleShift = Math.round((current - targetOffset) / root.realCount) * root.realCount;
                    targetOffset += cycleShift;
                }

                targetOffset += (event.angleDelta.y / 120.0) * 1.4 * wheelBoost;

                offsetAnim.stop();
                offsetAnim.from = current;
                offsetAnim.to = targetOffset;
                offsetAnim.restart();
            }
        }

        Connections {
            target: ctrl
            function onCurrentChannelIndexChanged() { root.forceCenterScrollSync(); }
        }

        delegate: ChannelSidebarDelegate {
            width: channelPathView.width
            sidebarModel: root.model
            currentChannelIndex: root.currentChannelIndex
            onClickedReal: realIndex => root.channelSelected(realIndex)
            onHoveredReal: channelName => root.channelHovered(channelName)
            appThemeItem: root.appThemeItem
        }
    }

    ChannelSidebarScrollTrack {
        id: sidebarScrollTrack
        realCount: root.realCount
        visibleRows: root.visibleRowsCount()
        currentPos: {
            if (root.realCount <= 1)
                return 0;
            var centerIdx = ((root.realCount - channelPathView.offset + channelPathView.centerSlot) % root.realCount + root.realCount) % root.realCount;
            if (centerIdx > (root.realCount - 0.5) || centerIdx < 0.45)
                return 0;
            if (centerIdx > (root.realCount - 1.55))
                return root.realCount - 1;
            return centerIdx;
        }
        appThemeItem: root.appThemeItem

        onScrubRequested: targetIndex => {
            offsetAnim.stop();
            if (root.realCount <= 0)
                return;
            channelPathView.offset = ((root.realCount - targetIndex + channelPathView.centerSlot) % root.realCount + root.realCount) % root.realCount;
        }

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.topMargin: root.outerMargin + root.px(16)
        anchors.bottomMargin: root.outerMargin + root.px(16)
        anchors.rightMargin: root.px(2)
    }
}
