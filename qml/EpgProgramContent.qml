// qml/EpgProgramContent.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    required property bool isFullScreen
    required property string channelLogo
    required property string epgTitle
    required property string epgDescription

    property var activeChannelModel: typeof channelModel !== "undefined" ? channelModel : null
    property string activeChannelName: typeof ctrl !== "undefined" ? ctrl.osdChannelName : ""
    property int currentTimestamp: Math.floor(Date.now() / 1000)

    Timer {
        id: currentProgramExpiryMonitor
        interval: 1000
        running: root.visible && root.stopTimestamp > 0
        repeat: true
        onTriggered: {
            root.currentTimestamp = Math.floor(Date.now() / 1000);
            if (root.currentTimestamp >= root.stopTimestamp && root.activeChannelModel && root.activeChannelName !== "") {
                var epgData = root.activeChannelModel.fetch_current_epg(root.activeChannelName);
                if (epgData && typeof ctrl !== "undefined") {
                    ctrl.epgTitle = epgData.title;
                    ctrl.epgDescription = epgData.description;
                }
            }
        }
    }

    readonly property var extractedEpgObj: root.activeChannelModel && root.activeChannelName !== "" ? root.activeChannelModel.fetch_current_epg(root.activeChannelName) : null
    readonly property int startTimestamp: extractedEpgObj ? (extractedEpgObj.start_ts || 0) : 0
    readonly property int stopTimestamp: extractedEpgObj ? (extractedEpgObj.stop_ts || 0) : 0

    RowLayout {
        anchors.fill: parent
        spacing: 20

        Rectangle {
            Layout.preferredWidth: 60
            Layout.preferredHeight: 60
            color: typeof appTheme !== "undefined" ? appTheme.logoBg : "transparent"
            radius: 8
            Layout.alignment: Qt.AlignTop

            Image {
                id: targetChannelLogoItem
                anchors.fill: parent
                anchors.margins: 4
                source: root.channelLogo
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 120
                sourceSize.height: 120
                cache: true
                onStatusChanged: {
                    if (status === Image.Error || root.channelLogo === "") {
                        source = "image://theme/media-playback-start";
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: descFlickable
                anchors.fill: parent
                contentWidth: width
                contentHeight: scrollContentLayout.implicitHeight
                anchors.rightMargin: 24
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                WheelHandler {
                    id: contentScrollShield
                    orientation: Qt.Vertical
                    onWheel: event => {
                        if (event.angleDelta.y > 0) {
                            descFlickable.contentY = Math.max(0, descFlickable.contentY - 25);
                        } else {
                            descFlickable.contentY = Math.min(descFlickable.contentHeight - descFlickable.height, descFlickable.contentY + 25);
                        }
                        event.accepted = true;
                    }
                }

                ColumnLayout {
                    id: scrollContentLayout
                    width: descFlickable.width
                    spacing: 8

                    readonly property int closeBracketIndex: root.epgTitle.indexOf("]")
                    readonly property bool hasTime: root.epgTitle.startsWith("[") && closeBracketIndex !== -1

                    readonly property string rawTimeStr: hasTime ? root.epgTitle.substring(1, closeBracketIndex).trim() : ""
                    readonly property string formattedTime: scrollContentLayout.rawTimeStr ? scrollContentLayout.rawTimeStr.replace(/\s*-\s*/, " ➔ ") : ""

                    // Fila horizontal elástica para la píldora y la barra juntas
                    RowLayout {
                        visible: scrollContentLayout.hasTime
                        spacing: 12
                        Layout.alignment: Qt.AlignVCenter

                        // 🚀 CORRECCIÓN DE LAYOUT: Forzamos al RowLayout a rellenar el ancho de la columna de forma explícita
                        Layout.fillWidth: true

                        // Píldora Horaria
                        Rectangle {
                            id: drawerTimeBadge
                            color: appTheme.bgItemActive
                            radius: appTheme.px ? appTheme.px(5) : 5
                            Layout.preferredHeight: appTheme.px ? appTheme.px(24) : 24
                            Layout.preferredWidth: drawerTimeLayout.implicitWidth + (appTheme.px ? appTheme.px(16) : 16)
                            Layout.alignment: Qt.AlignVCenter

                            RowLayout {
                                id: drawerTimeLayout
                                anchors.centerIn: parent
                                spacing: 0

                                Text {
                                    text: scrollContentLayout.formattedTime
                                    color: appTheme.getW3cContrast(drawerTimeBadge.color)
                                    font.bold: true
                                    font.pointSize: root.isFullScreen ? 11 : 10
                                    font.family: "Monospace"
                                    renderType: Text.NativeRendering
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                        }

                        // Barra de progreso elástica alineada a la derecha
                        Rectangle {
                            id: drawerProgressBarContainer
                            visible: root.stopTimestamp > root.startTimestamp
                            Layout.fillWidth: true
                            Layout.preferredHeight: appTheme.px ? appTheme.px(4) : 4
                            Layout.alignment: Qt.AlignVCenter
                            color: "#334155"
                            radius: 2

                            readonly property real progressFactor: Math.max(0.0, Math.min(1.0, (root.currentTimestamp - root.startTimestamp) / (root.stopTimestamp - root.startTimestamp)))

                            Rectangle {
                                width: parent.width * parent.progressFactor
                                height: parent.height
                                radius: 2
                                color: appTheme.borderActive
                            }
                        }
                    }

                    // Cuerpo de la Sinopsis
                    Text {
                        id: descriptionText
                        Layout.fillWidth: true
                        text: root.epgDescription
                        color: "#CBD5E1"
                        font.pointSize: root.isFullScreen ? 11 : 10
                        renderType: Text.NativeRendering
                        wrapMode: Text.WordWrap
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: descFlickable.contentHeight > descFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: "#FFFFFF"
                    }
                }
            }
        }
    }
}
