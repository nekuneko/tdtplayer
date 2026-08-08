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

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    
    // 🚀 MEJORA GEOMÉTRICA: Ancho fijado de forma estricta para evitar recálculos de layout continuos
    width: 290
    visible: !root.isFullScreen || root.sidebarForceOpen
    hoverEnabled: true

    // 🚀 OPTIMIZACIÓN POR HARDWARE DE TRANSICIÓN:
    // Convierte el panel en una textura estática en la GPU únicamente mientras se está moviendo,
    // evitando que el ListView recalcule las filas virtuales en caliente.
    layer.enabled: sidebarXAnimation.running
    layer.smooth: false

    // Modificación de coordenadas: si debe abrirse se pega al borde derecho (parent.width - width), si no se esconde fuera
    x: (root.visible && root.sidebarForceOpen) ? (parent.width - width) : parent.width

    Behavior on x { 
        NumberAnimation { 
            id: sidebarXAnimation
            duration: 220 
            easing.type: Easing.OutCubic // Curva cinemática más suave y rápida para interfaces de TV
        } 
    }

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
        color: appTheme.bgItemDefault
    }

    ListView {
        id: channelListView; anchors.fill: parent; clip: true; model: 1000000
        
        // Optimizaciones nativas para listas masivas en Qt6
        reuseItems: true
        maximumFlickVelocity: 4000
        
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
