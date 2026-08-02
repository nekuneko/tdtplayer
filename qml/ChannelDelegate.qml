// ChannelDelegate.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    id: control
    width: 290
    height: 60
    hoverEnabled: true
    
    // Propiedades requeridas corregidas
    required property var sidebarModel
    required property int modelRow
    required property int currentChannelIndex

    signal clickedReal(int realIndex)
    signal hoveredReal(string channelName)

    // Cálculo matemático limpio para el scroll infinito
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
        width: 270
        anchors.centerIn: parent
        spacing: 12
        
        Image {
            // SOLUCIÓN: Generamos el QModelIndex de Python de forma explícita pasándole el entero realIndex
            source: (control.sidebarModel && control.sidebarModel.rowCount() > 0) 
                    ? control.sidebarModel.data(control.sidebarModel.index(control.realIndex, 0), Qt.UserRole + 3) 
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
            // SOLUCIÓN: Enlace de datos correcto para evitar nombres repetidos
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

        Text {
            property string chNoStr: (control.sidebarModel && control.sidebarModel.rowCount() > 0) 
                                     ? control.sidebarModel.data(control.sidebarModel.index(control.realIndex, 0), Qt.UserRole + 4) 
                                     : ""
            property string finalChNo: chNoStr !== "" ? chNoStr : control.realIndex.toString()
            text: "CH " + finalChNo.padStart(2, '0')
            color: control.highlighted 
                   ? "#3B82F6" 
                   : (control.hovered ? "#94A3B8" : "#64748B")
            font.pointSize: 9
            Behavior on color { ColorAnimation { duration: 150 } }
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
