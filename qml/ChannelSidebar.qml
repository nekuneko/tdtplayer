// qml/ChannelSidebar.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

MouseArea {
    id: root
    property var model
    property int currentChannelIndex: 0
    property bool isFullScreen: false
    property bool sidebarForceOpen: false
    property var appThemeItem: null

    signal channelSelected(int realIndex)
    signal channelHovered(string channelName)

    readonly property real outerMargin: root.appThemeItem ? root.appThemeItem.px(12) : 12

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    width: (parent
           ? Math.min(root.appThemeItem ? root.appThemeItem.px(320) : 320, Math.max(root.appThemeItem ? root.appThemeItem.px(195) : 195, parent.width * 0.44))
           : (root.appThemeItem ? root.appThemeItem.px(320) : 320)) + outerMargin

    visible: !root.isFullScreen || root.sidebarForceOpen
    hoverEnabled: true

    layer.enabled: sidebarXAnimation.running
    layer.smooth: false

    x: (root.visible && root.sidebarForceOpen) ? (parent.width - width) : parent.width

    onVisibleChanged: {
        if (visible && root.model && root.model.refresh_sidebar_epg) {
            root.model.refresh_sidebar_epg();
        }
    }

    onSidebarForceOpenChanged: {
        if (sidebarForceOpen) {
            root.forceCenterScrollSync();
            if (root.model && root.model.refresh_sidebar_epg) {
                root.model.refresh_sidebar_epg();
            }
        } else if (typeof ctrl !== "undefined") {
            ctrl.cancelPendingZapping();
        }
    }

    Timer {
        id: sidebarEpgRefreshTimer
        interval: 15000
        running: root.visible
        repeat: true
        onTriggered: {
            if (root.model && root.model.refresh_sidebar_epg) {
                root.model.refresh_sidebar_epg();
            }
        }
    }

    Behavior on x {
        NumberAnimation {
            id: sidebarXAnimation
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    onExited: {
        sidebarForceOpen = false;
        root.forceCenterScrollSync();
    }

    function positionListView(index, mode) {
        if (!sidebarXAnimation.running && root.model && index >= 0 && index < root.model.rowCount()) {
            channelListView.positionViewAtIndex(index, mode);
        }
    }

    function getCurrentScrollIndex() {
        return channelListView.indexAt(0, channelListView.contentY);
    }

    function forceKeyboardScrollSync() {
        if (sidebarXAnimation.running || !root.model)
            return;
        var count = root.model.rowCount();
        if (count === 0)
            return;
        var rowHeight = root.appThemeItem ? root.appThemeItem.px(72) : 72;
        var visibleCount = Math.floor(channelListView.height / rowHeight);
        var firstVisible = channelListView.indexAt(0, channelListView.contentY);
        var lastVisible = firstVisible + visibleCount - 1;
        var target = root.currentChannelIndex;

        if (target >= 0 && target < count) {
            if (target > lastVisible)
                channelListView.positionViewAtIndex(target, ListView.Beginning);
            else if (target < firstVisible)
                channelListView.positionViewAtIndex(target, ListView.End);
        }
    }

    function forceCenterScrollSync() {
        if (sidebarXAnimation.running || !root.model)
            return;
        var count = root.model.rowCount();
        if (count === 0)
            return;
        if (root.currentChannelIndex >= 0 && root.currentChannelIndex < count) {
            channelListView.positionViewAtIndex(root.currentChannelIndex, ListView.Center);
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: root.outerMargin
        color: root.appThemeItem ? root.appThemeItem.bgAbsolute : "#0B0F17"
        radius: root.appThemeItem ? root.appThemeItem.px(16) : 16
        border.color: root.appThemeItem ? root.appThemeItem.borderDefault : "#1E293B"
        border.width: 1
    }

    ListView {
        id: channelListView
        anchors.fill: parent
        anchors.margins: root.outerMargin + (root.appThemeItem ? root.appThemeItem.px(10) : 10)
        spacing: root.appThemeItem ? root.appThemeItem.px(8) : 8
        clip: true
        model: root.model

        reuseItems: true
        cacheBuffer: 0
        maximumFlickVelocity: 2000

        WheelHandler {
            id: sidebarExploreWheel
            orientation: Qt.Vertical
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                channelListView.flick(0, event.angleDelta.y * 8);
            }
        }

        Connections {
            target: ctrl
            function onCurrentChannelIndexChanged() {
                if (sidebarXAnimation.running || !root.model)
                    return;
                var count = root.model.rowCount();
                if (count === 0)
                    return;
                if (ctrl.currentChannelIndex >= 0 && ctrl.currentChannelIndex < count) {
                    channelListView.positionViewAtIndex(ctrl.currentChannelIndex, ListView.Center);
                }
            }
        }

        delegate: ChannelSidebarDelegate {
            sidebarModel: root.model
            currentChannelIndex: root.currentChannelIndex
            onClickedReal: function (realIndex) {
                root.channelSelected(realIndex);
            }
            onHoveredReal: function (channelName) {
                root.channelHovered(channelName);
            }
            appThemeItem: root.appThemeItem
        }
    }
}
