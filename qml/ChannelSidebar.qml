// ChannelSidebar.qml
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

    // ACTUALIZADO: Forzar el cálculo de centrado cuando el ratón sale
    onExited: {
        // El panel SOLO se cierra si el ratón abandona físicamente las coordenadas del área
        if (root.isFullScreen) {
            root.sidebarForceOpen = false
        }
        
        // Recalcula la posición media de manera estática al retirar el cursor
        var count = root.model ? root.model.rowCount() : 0;
        if (count > 0) {
            var currentScrollIndex = channelListView.indexAt(0, channelListView.contentY)
            var baseVirtual = currentScrollIndex - (currentScrollIndex % count)
            var targetVirtual = baseVirtual + root.currentChannelIndex
            channelListView.positionViewAtIndex(targetVirtual, ListView.Center)
        }
    }

    // Expone el ListView interno para poder usar positionViewAtIndex desde fuera
    function positionListView(index, mode) {
        channelListView.positionViewAtIndex(index, mode);
    }
    
    function getCurrentScrollIndex() {
        return channelListView.indexAt(0, channelListView.contentY);
    }

    // 👇 NUEVO: Función para sincronizar la vista cuando se navega estrictamente con teclado
    function forceKeyboardScrollSync() {
        var count = root.model ? root.model.rowCount() : 0;
        if (count === 0) return;
        
        var currentScrollIndex = channelListView.indexAt(0, channelListView.contentY);
        var baseVirtual = currentScrollIndex - (currentScrollIndex % count);
        var targetVirtual = baseVirtual + root.currentChannelIndex;
        
        // Desplaza el ListView de forma que el elemento activo se mantenga visible en el centro
        channelListView.positionViewAtIndex(targetVirtual, ListView.Center);
    }

    

    Rectangle {
        anchors.fill: parent
        color: "#111827"
    }

    Behavior on width {
        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
    }

    ListView {
        id: channelListView
        anchors.fill: parent
        clip: true
        model: 1000000

        // 🛠️ REPARADO: Se cambió el objetivo de 'window' al ID del controlador 'ctrl'
        Connections {
            target: ctrl 
            
            // Ahora la señal coincide perfectamente porque ctrl (PlaybackController) 
            // es quien posee la propiedad 'currentChannelIndex'
            function onCurrentChannelIndexChanged() {
                var count = root.model ? root.model.rowCount() : 0;
                if (count === 0) return;
                
                // Si el usuario tiene el ratón dentro de la barra lateral, no alteramos el scroll
                if (root.containsMouse) return;
                
                var currentScrollIndex = channelListView.indexAt(0, channelListView.contentY)
                var baseVirtual = currentScrollIndex - (currentScrollIndex % count)
                var targetVirtual = baseVirtual + ctrl.currentChannelIndex
                
                channelListView.positionViewAtIndex(targetVirtual, ListView.Center)
            }
        }


        delegate: ItemDelegate {
            id: channelItemDelegate
            width: 290
            height: 60
            hoverEnabled: true
            
            property int realIndex: (root.model && root.model.rowCount() > 0) ? (index % root.model.rowCount()) : 0
            highlighted: root.currentChannelIndex === realIndex

            background: Rectangle {
                color: channelItemDelegate.highlighted 
                       ? "#1E3A8A" 
                       : (channelItemDelegate.hovered ? "#334155" : "transparent") 
                opacity: channelItemDelegate.highlighted ? 0.4 : 0.6
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            contentItem: RowLayout {
                width: 270
                anchors.centerIn: parent
                spacing: 12
                
                Image {
                    source: (root.model && root.model.rowCount() > 0) 
                            ? root.model.data(root.model.index(channelItemDelegate.realIndex, 0), Qt.UserRole + 3) 
                            : ""
                    sourceSize.width: 35
                    sourceSize.height: 35
                    Layout.preferredWidth: 35
                    Layout.preferredHeight: 35
                    fillMode: Image.PreserveAspectFit
                    onStatusChanged: {
                        if (status === Image.Error) {
                            source = "image://theme/media-playback-start"
                        }
                    }
                }

                Text {
                    text: (root.model && root.model.rowCount() > 0) 
                          ? root.model.data(root.model.index(channelItemDelegate.realIndex, 0), Qt.UserRole + 1) 
                          : ""
                    color: channelItemDelegate.highlighted 
                           ? "#3B82F6" 
                           : (channelItemDelegate.hovered ? "#FFFFFF" : "#E2E8F0") 
                    font.bold: channelItemDelegate.highlighted
                    font.pointSize: 11
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Text {
                    property string chNoStr: (root.model && root.model.rowCount() > 0) 
                                             ? root.model.data(root.model.index(channelItemDelegate.realIndex, 0), Qt.UserRole + 4) 
                                             : ""
                    property string finalChNo: chNoStr !== "" ? chNoStr : channelItemDelegate.realIndex.toString()
                    text: "CH " + finalChNo.padStart(2, '0')
                    color: channelItemDelegate.highlighted 
                           ? "#3B82F6" 
                           : (channelItemDelegate.hovered ? "#94A3B8" : "#64748B")
                    font.pointSize: 9
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            onClicked: {
                root.channelSelected(channelItemDelegate.realIndex)
                // ❌ ELIMINA O COMENTA ESTA LÍNEA:
                // sidebar.sidebarForceOpen = false 
            }
            
            onHoveredChanged: {
                if (hovered && (root.model && root.model.rowCount() > 0)) {
                    var name = root.model.data(root.model.index(channelItemDelegate.realIndex, 0), Qt.UserRole + 1);
                    if (name !== "") {
                        root.channelHovered(name);
                    }
                }
            }
        } 
    }
}
