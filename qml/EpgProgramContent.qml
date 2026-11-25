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
    property string activeChannelName: typeof ctrl !== "undefined" ? (ctrl.osdHoveredChannelName !== "" ? ctrl.osdHoveredChannelName : ctrl.osdChannelName) : ""
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
        spacing: root.width < (typeof appTheme !== "undefined" && appTheme ? appTheme.px(260) : 260) ? 10 : 20

        Rectangle {
            visible: root.width >= (typeof appTheme !== "undefined" && appTheme ? appTheme.px(230) : 230)
            Layout.preferredWidth: 60
            Layout.preferredHeight: 60
            color: typeof appTheme !== "undefined" ? appTheme.logoBg : "transparent"
            radius: 8
            Layout.alignment: Qt.AlignTop

            Text {
                anchors.centerIn: parent
                visible: drawerChannelLogo.status === Image.Error || root.channelLogo === ""
                text: root.activeChannelName !== "" ? root.activeChannelName.substring(0, 1).toUpperCase() : "📺"
                color: "#FFFFFF"
                font.bold: true
                font.pointSize: appTheme ? appTheme.pt(16) : 16
                renderType: Text.QtRendering
            }

            Image {
                id: drawerChannelLogo
                anchors.fill: parent
                anchors.margins: 4
                source: (root.channelLogo.startsWith("file://") || root.channelLogo.startsWith("http")) ? root.channelLogo : ""
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 120
                sourceSize.height: 120
                visible: status === Image.Ready && source !== ""
                cache: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.fillHeight: true
            spacing: 8

            EpgProgressRow {
                isFullScreen: root.isFullScreen
                epgTitle: root.epgTitle
                startTimestamp: root.startTimestamp
                stopTimestamp: root.stopTimestamp
                currentTimestamp: root.currentTimestamp
            }

            Flickable {
                id: descFlickable
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: descriptionText.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                readonly property bool hasScrollbar: descFlickable.contentHeight > descFlickable.height

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

                Text {
                    id: descriptionText
                    width: Math.max(0, descFlickable.width - 14)
                    text: root.epgDescription
                    color: "#CBD5E1"
                    font.pointSize: root.isFullScreen ? 11 : 10
                    renderType: Text.NativeRendering
                    wrapMode: Text.WordWrap
                }

                ScrollBar.vertical: ScrollBar {
                    policy: descFlickable.hasScrollbar ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
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
