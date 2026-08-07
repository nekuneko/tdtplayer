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

    signal channelSelected(int realIndex)
    signal channelHovered(string channelName)

    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    
    visible: !root.isFullScreen || root.sidebarForceOpen
    width: visible ? 290 : 0
    hoverEnabled: true

    onExited: {
        if (root.isFullScreen) { sidebarForceOpen = false }
        var count = root.model ? root.model.rowCount() : 0;
        if (count > 0) {
            var currentScrollIndex = channelListView.indexAt(0, channelListView.contentY)
            var baseVirtual = currentScrollIndex - (currentScrollIndex % count)
            var targetVirtual = baseVirtual + root.currentChannelIndex
            channelListView.positionViewAtIndex(targetVirtual, ListView.Center)
        }
    }

    function positionListView(index, mode) { channelListView.positionViewAtIndex(index, mode); }
    function getCurrentScrollIndex() { return channelListView.indexAt(0, channelListView.contentY); }

    function forceKeyboardScrollSync() {
        var count = root.model ? root.model.rowCount() : 0; if (count === 0) return;
        var visibleCount = Math.floor(channelListView.height / 60);
        var firstVisibleVirtual = channelListView.indexAt(0, channelListView.contentY);
        var lastVisibleVirtual = firstVisibleVirtual + visibleCount - 1;
        var baseVirtual = firstVisibleVirtual - (firstVisibleVirtual % count);
        var targetVirtual = baseVirtual + root.currentChannelIndex;
        
        if (targetVirtual < firstVisibleVirtual && (targetVirtual + count) <= lastVisibleVirtual + count) targetVirtual += count;
        else if (targetVirtual > lastVisibleVirtual && (targetVirtual - count) >= firstVisibleVirtual - count) targetVirtual -= count;

        if (targetVirtual > lastVisibleVirtual) channelListView.positionViewAtIndex(targetVirtual, ListView.Beginning);
        else if (targetVirtual < firstVisibleVirtual) channelListView.positionViewAtIndex(targetVirtual, ListView.End);
    }

    function forceCenterScrollSync() {
        var count = root.model ? root.model.rowCount() : 0; if (count === 0) return;
        var currentScrollIndex = channelListView.indexAt(0, channelListView.contentY);
        var baseVirtual = currentScrollIndex - (currentScrollIndex % count);
        var targetVirtual = baseVirtual + root.currentChannelIndex;
        channelListView.positionViewAtIndex(targetVirtual, ListView.Center);
    }

    Rectangle {
        anchors.fill: parent
        // 🚀 ENLACE DINÁMICO DE PALETA: Cambia de color en sintonía con la rejilla principal
        color: appTheme.bgItemDefault
    }

    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

    ListView {
        id: channelListView; anchors.fill: parent; clip: true; model: 1000000
        Connections {
            target: ctrl 
            function onCurrentChannelIndexChanged() {
                if (!root.model) return; var count = root.model.rowCount(); if (count === 0 || root.containsMouse) return;
                var currentScrollIndex = channelListView.indexAt(0, channelListView.contentY);
                var baseVirtual = currentScrollIndex - (currentScrollIndex % count);
                var targetVirtual = baseVirtual + ctrl.currentChannelIndex;
                channelListView.positionViewAtIndex(targetVirtual, ListView.Center);
            }
        }
        delegate: ChannelDelegate {
            sidebarModel: root.model; required property int index; required property var model
            modelRow: index; currentChannelIndex: root.currentChannelIndex
            onClickedReal: function(realIndex) { root.channelSelected(realIndex) }
            onHoveredReal: function(channelName) { root.channelHovered(channelName) }
        }
    }
}
