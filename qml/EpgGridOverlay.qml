// qml/EpgGridOverlay.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: root
    anchors.fill: parent
    visible: false
    opacity: 0.0
    objectName: "epgGridOverlayLoader"

    required property var channelModel
    required property int currentChannelIndex
    required property var appThemeItem
    property string currentViewMode: "NOW"
    property int sharedNowTimestamp: Math.floor(Date.now() / 1000)

    signal channelSelected(int realIndex)
    signal closeRequested

    readonly property real outerMargin: root.appThemeItem ? root.appThemeItem.px(12) : 12
    readonly property real effectiveWidth: parent ? parent.width : width
    readonly property real uiScale: Math.max(0.84, Math.min(1.18, effectiveWidth / 1280))
    readonly property bool isCompactHeader: effectiveWidth < (root.appThemeItem ? root.appThemeItem.px(920) : 920)

    Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
    }

    Timer {
        id: sharedClockTimer
        interval: 15000
        running: root.visible && root.currentViewMode === "NOW"
        repeat: true
        onTriggered: root.sharedNowTimestamp = Math.floor(Date.now() / 1000)
    }

    onVisibleChanged: {
        if (visible) {
            if (typeof playerView !== "undefined" && playerView) {
                playerView.resetMouseCursor();
            }
            root.sharedNowTimestamp = Math.floor(Date.now() / 1000);
            root.opacity = 0.98;
            root.currentViewMode = "NOW";
            overlayListView.forceActiveFocus();
            root.currentChannelIndex = ctrl.currentChannelIndex;

            if (root.currentChannelIndex >= 0 && root.currentChannelIndex < root.channelModel.rowCount()) {
                overlayListView.currentIndex = root.currentChannelIndex;
                overlayListView.positionViewAtIndex(root.currentChannelIndex, ListView.Center);
            }
        } else {
            root.opacity = 0.0;
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_E) {
            root.closeRequested();
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab) {
            root.currentViewMode = root.currentViewMode === "NOW" ? "NEXT" : "NOW";
            event.accepted = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.55
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: {
            if (typeof playerView !== "undefined" && playerView) {
                playerView.resetMouseCursor();
            }
        }
        onWheel: event => event.accepted = true
    }

    Rectangle {
        id: gridCardContainer
        anchors.fill: parent
        anchors.margins: root.outerMargin
        color: root.appThemeItem.bgAbsolute
        radius: root.appThemeItem ? root.appThemeItem.px(16) : 16
        border.color: root.appThemeItem.borderDefault
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.isCompactHeader ? root.appThemeItem.px(16) : root.appThemeItem.px(22)
            spacing: root.appThemeItem.px(14)

            EpgGridHeader {
                appThemeItem: root.appThemeItem
                currentViewMode: root.currentViewMode
                isCompactHeader: root.isCompactHeader
                containerWidth: root.effectiveWidth - (root.outerMargin * 2)
                uiScale: root.uiScale
                onViewModeSelected: mode => root.currentViewMode = mode
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: root.appThemeItem.borderDefault
            }

            ListView {
                id: overlayListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.channelModel
                clip: true
                spacing: root.appThemeItem.px(8)
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: true
                focus: true
                rightMargin: root.appThemeItem.px(10)

                delegate: EpgGridDelegate {
                    width: overlayListView.width - overlayListView.rightMargin
                    channelModel: root.channelModel
                    currentChannelIndex: root.currentChannelIndex
                    currentTimestamp: root.sharedNowTimestamp
                    uiScale: root.uiScale
                    viewMode: root.currentViewMode
                    onClicked: root.channelSelected(itemIndex)
                    appThemeItem: root.appThemeItem
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 5
                        radius: 3
                        color: root.appThemeItem.borderHover
                    }
                }
            }
        }
    }
}
