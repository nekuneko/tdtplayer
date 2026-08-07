// qml/EpgDrawer.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    
    // Propiedades de la interfaz del componente
    property string channelName: ""
    property string channelNo: ""
    property string hoveredChannelName: ""
    property string channelLogo: "" 
    property string epgTitle: ""
    property string epgDescription: ""
    property bool isFullScreen: false
    property var sidebarItem: null
    property bool epgForceOpen: false

    // Propiedad expuesta de solo lectura para que main.qml pueda saber si el ratón está encima de forma segura
    readonly property bool containsMouse: epgMouseTracker.containsMouse

    height: root.isFullScreen ? 180 : 160 
    
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.left: parent ? parent.left : undefined
    
    color: "#0F172A" 
    opacity: 0.96
    border.color: "#3B82F6"
    border.width: root.isFullScreen ? 1 : 0

    Behavior on height {
        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
    }

    // Gestor que captura el movimiento del ratón sobre la superficie del EPG
    MouseArea {
        id: epgMouseTracker
        anchors.fill: parent
        hoverEnabled: true
        z: -1 
        onExited: {
            root.epgForceOpen = false
        }
    }

    // Contenedor principal con márgenes limpios
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // FILA SUPERIOR: Identificación del Canal
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignLeft

                Rectangle {
                    visible: root.channelNo !== ""
                    color: "#3B82F6"
                    radius: 4
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 22
                    
                    Text {
                        anchors.centerIn: parent
                        text: root.channelNo.padStart(2, '0')
                        color: "white"
                        font.bold: true
                        font.pointSize: 10
                    }
                }

                Text {
                    readonly property string targetedChannel: root.hoveredChannelName !== "" ? root.hoveredChannelName : root.channelName
                    text: targetedChannel
                    color: "white"
                    font.bold: true
                    font.pointSize: root.isFullScreen ? 14 : 12
                    elide: Text.ElideRight
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                color: "#EF4444" 
                radius: 4
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignRight
                Layout.preferredWidth: liveRowLayout.implicitWidth + 16 

                RowLayout {
                    id: liveRowLayout
                    anchors.centerIn: parent
                    spacing: 6
                    Rectangle { width: 6; height: 6; radius: 3; color: "white"; Layout.alignment: Qt.AlignVCenter }
                    Text {
                        text: "EN DIRECTO AHORA"
                        color: "white"
                        font.bold: true
                        font.pointSize: 8
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#334155"
        }

        // FILA INFERIOR: CONTENIDO (LOGO + GUÍA CON SCROLL REPARADO)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 20

            Rectangle {
                Layout.preferredWidth: 60
                Layout.preferredHeight: 60
                color: "#1E293B"
                radius: 8
                Layout.alignment: Qt.AlignTop

                Image {
                    id: channelLogoImage
                    anchors.fill: parent
                    anchors.margins: 4
                    source: root.channelLogo
                    fillMode: Image.PreserveAspectFit
                    
                    onStatusChanged: {
                        if (status === Image.Error || root.channelLogo === "") {
                            source = "image://theme/media-playback-start"
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                Text {
                    text: root.epgTitle
                    color: "#3B82F6" 
                    font.bold: true
                    font.pointSize: root.isFullScreen ? 13 : 11
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    Flickable {
                        id: descFlickable
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: descriptionText.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        WheelHandler {
                            id: textScrollWheel
                            orientation: Qt.Vertical
                            onWheel: (event) => {
                                if (event.angleDelta.y > 0) {
                                    descFlickable.contentY = Math.max(0, descFlickable.contentY - 20)
                                } else {
                                    descFlickable.contentY = Math.min(descFlickable.contentHeight - descFlickable.height, descFlickable.contentY + 20)
                                }
                                event.accepted = true
                            }
                        }

                        Text {
                            id: descriptionText
                            width: descFlickable.width
                            text: root.epgDescription
                            color: "#94A3B8"
                            font.pointSize: root.isFullScreen ? 11 : 10
                            wrapMode: Text.WordWrap
                        }

                        ScrollBar.vertical: ScrollBar {
                            id: verticalScrollBar
                            policy: descFlickable.contentHeight > descFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                            
                            contentItem: Rectangle {
                                implicitWidth: 4
                                radius: 2
                                color: "#475569"
                            }
                        }
                    }
                }
            }
        }
    }

    WheelHandler {
        id: drawerVolumeWheel
        orientation: Qt.Vertical
        onWheel: (event) => {
            if (event.angleDelta.y > 0) {
                ctrl.changeVolume(5)
            } else if (event.angleDelta.y < 0) {
                ctrl.changeVolume(-5)
            }
        }
    }
}
