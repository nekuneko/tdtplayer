// qml/ChannelDelegate.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    id: control
    width: 290
    height: 60
    hoverEnabled: true
    
    // Propiedades requeridas
    required property var sidebarModel
    required property int modelRow
    required property int currentChannelIndex

    signal clickedReal(int realIndex)
    signal hoveredReal(string channelName)

    // Cálculo matemático para el scroll infinito
    readonly property int realIndex: (sidebarModel && sidebarModel.rowCount() > 0) ? (modelRow % sidebarModel.rowCount()) : 0
    highlighted: currentChannelIndex === realIndex

    background: Rectangle {
        color: control.highlighted 
               ? "#1E3A8A" 
               : (control.hovered ? "#334155" : "transparent") 
        opacity: control.highlighted ? 0.4 : 0.6
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    contentItem: RowLayout {
        // 🚀 MEJORA ESTRUCTURAL: Incrementamos el margen derecho a 15 para despegar la caja del borde
        width: 255
        anchors.centerIn: parent
        anchors.rightMargin: 15 
        spacing: 12
        
        Image {
            source: (control.sidebarModel && control.sidebarModel.rowCount() > 0) 
                    ? control.sidebarModel.data(control.sidebarModel.index(control.realIndex, 0), Qt.UserRole + 3) 
                    : ""
            sourceSize.width: 35
            sourceSize.height: 35
            Layout.preferredWidth: 35
            Layout.preferredHeight: 35
            fillMode: Image.PreserveAspectFit
            cache: true
            onStatusChanged: {
                if (status === Image.Error) {
                    source = "image://theme/media-playback-start"
                }
            }
        }

        Text {
            text: (control.sidebarModel && control.sidebarModel.rowCount() > 0) 
                  ? control.sidebarModel.data(control.sidebarModel.index(control.realIndex, 0), Qt.UserRole + 1) 
                  : ""
            color: control.highlighted 
                   ? "#3B82F6" 
                   : (control.hovered ? "#FFFFFF" : "#E2E8F0") 
            font.bold: control.highlighted
            font.pointSize: 11
            Layout.fillWidth: true
            elide: Text.ElideRight
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // Caja cuadrada con bordes redondeados (Badge idéntico al EPG)
        Rectangle {
            id: badgeContainer
            property string chNoStr: (control.sidebarModel && control.sidebarModel.rowCount() > 0) 
                                     ? control.sidebarModel.data(control.sidebarModel.index(control.realIndex, 0), Qt.UserRole + 4) 
                                     : ""
            property string finalChNo: chNoStr !== "" ? chNoStr : control.realIndex.toString()

            color: control.highlighted ? "#3B82F6" : (control.hovered ? "#2563EB" : "#1D4ED8")
            opacity: control.highlighted || control.hovered ? 1.0 : 0.8
            radius: 4

            Layout.preferredHeight: 22
            Layout.preferredWidth: channelNumberText.implicitWidth + 14
            Layout.alignment: Qt.AlignVCenter
            
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                id: channelNumberText
                anchors.centerIn: parent
                text: parent.finalChNo.padStart(2, '0')
                
                color: "white"
                font.bold: true
                font.pointSize: 10
                // 🚀 UNIFICACIÓN TIPOGRÁFICA: Eliminamos Monospace para usar la misma fuente que el EpgDrawer
            }
        }
    }

    onClicked: {
        control.clickedReal(control.realIndex)
    }
    
    onHoveredChanged: {
        if (hovered && (control.sidebarModel && control.sidebarModel.rowCount() > 0)) {
            var name = control.sidebarModel.data(control.sidebarModel.index(control.realIndex, 0), Qt.UserRole + 1);
            if (name !== "") {
                control.hoveredReal(name);
            }
        }
    }
}
