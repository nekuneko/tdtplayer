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

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    
    width: root.appThemeItem ? root.appThemeItem.px(290) : 290
    visible: !root.isFullScreen || root.sidebarForceOpen
    hoverEnabled: true

    layer.enabled: sidebarXAnimation.running
    layer.smooth: false

    x: (root.visible && root.sidebarForceOpen) ? (parent.width - width) : parent.width

    Behavior on x { 
        NumberAnimation { 
            id: sidebarXAnimation
            duration: 220 
            easing.type: Easing.OutCubic 
        } 
    }

    onExited: {
        if (sidebarXAnimation.running) return
        if (root.isFullScreen) { sidebarForceOpen = false }
        var count = root.model ? root.model.rowCount() : 0
        if (count > 0) {
            var currentScrollIndex = channelListView.indexAt(0, channelListView.contentY)
            var baseVirtual = currentScrollIndex - (currentScrollIndex % count)
            var targetVirtual = baseVirtual + root.currentChannelIndex
            channelListView.positionViewAtIndex(targetVirtual, ListView.Center)
        }
    }

    // 🚀 RESTAURACIÓN CRÍTICA: Función nativa invocada por EpgDataLoader para indexar posiciones
    function positionListView(index, mode) { 
        if (!sidebarXAnimation.running) {
            channelListView.positionViewAtIndex(index, mode) 
        }
    }

    function getCurrentScrollIndex() { return channelListView.indexAt(0, channelListView.contentY) }

    function forceKeyboardScrollSync() {
        if (sidebarXAnimation.running) return
        var count = root.model ? root.model.rowCount() : 0; if (count === 0) return
        var rowHeight = root.appThemeItem ? root.appThemeItem.px(60) : 60
        var visibleCount = Math.floor(channelListView.height / rowHeight)
        var firstVisibleVirtual = channelListView.indexAt(0, channelListView.contentY)
        var lastVisibleVirtual = firstVisibleVirtual + visibleCount - 1
        var baseVirtual = firstVisibleVirtual - (firstVisibleVirtual % count)
        var targetVirtual = baseVirtual + root.currentChannelIndex
        
        if (targetVirtual < firstVisibleVirtual && (targetVirtual + count) <= lastVisibleVirtual + count) targetVirtual += count
        else if (targetVirtual > lastVisibleVirtual && (targetVirtual - count) >= firstVisibleVirtual - count) targetVirtual -= count

        if (targetVirtual > lastVisibleVirtual) channelListView.positionViewAtIndex(targetVirtual, ListView.Beginning)
        else if (targetVirtual < firstVisibleVirtual) channelListView.positionViewAtIndex(targetVirtual, ListView.End)
    }

    function forceCenterScrollSync() {
        if (sidebarXAnimation.running) return
        var count = root.model ? root.model.rowCount() : 0; if (count === 0) return
        var currentScrollIndex = channelListView.indexAt(0, channelListView.contentY)
        var baseVirtual = currentScrollIndex - (currentScrollIndex % count)
        var targetVirtual = baseVirtual + root.currentChannelIndex
        channelListView.positionViewAtIndex(targetVirtual, ListView.Center)
    }

    Rectangle {
        anchors.fill: parent
        color: root.appThemeItem ? root.appThemeItem.bgAbsolute : "#0B0F17"
    }

    ListView {
        id: channelListView
        anchors.fill: parent
        clip: true
        model: 1000000
        
        reuseItems: true
        maximumFlickVelocity: 4000
        cacheBuffer: root.appThemeItem ? root.appThemeItem.px(120) : 120
        
        Connections {
            target: ctrl 
            function onCurrentChannelIndexChanged() {
                if (sidebarXAnimation.running || !root.model || root.containsMouse) return
                var count = root.model.rowCount()
                if (count === 0) return
                var currentScrollIndex = channelListView.indexAt(0, channelListView.contentY)
                var baseVirtual = currentScrollIndex - (currentScrollIndex % count)
                var targetVirtual = baseVirtual + ctrl.currentChannelIndex
                channelListView.positionViewAtIndex(targetVirtual, ListView.Center)
            }
        }
        
        delegate: ChannelDelegate {
            sidebarModel: root.model
            required property int index
            required property var model
            modelRow: index
            currentChannelIndex: root.currentChannelIndex
            onClickedReal: function(realIndex) { root.channelSelected(realIndex) }
            onHoveredReal: function(channelName) { root.channelHovered(channelName) }
        }
    }
}
