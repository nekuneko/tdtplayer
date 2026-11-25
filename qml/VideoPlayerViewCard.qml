// qml/VideoPlayerViewCard.qml
import QtQuick
import QtMultimedia

Rectangle {
    id: videoContainer
    color: "black"

    required property bool isPip
    required property bool isCardMode
    required property bool isConfigOpen
    required property bool isSidebarOpen
    required property bool isEpgOpen
    required property real configWidth
    required property real sidebarWidth
    required property real epgHeight
    required property real cardMargin

    property alias videoOutputItem: videoOutput
    readonly property real sourceVideoHeight: videoOutput.sourceRect.height

    readonly property real leftInset: isCardMode ? (isConfigOpen ? configWidth : cardMargin) : 0
    readonly property real rightInset: isCardMode ? (isSidebarOpen ? sidebarWidth : cardMargin) : 0
    readonly property real bottomInset: isCardMode ? (cardMargin + (isEpgOpen ? (epgHeight + cardMargin) : 0)) : 0

    x: leftInset
    y: isCardMode ? cardMargin : 0
    width: Math.max(100, parent ? (parent.width - leftInset - rightInset) : 100)
    height: Math.max(80, parent ? (parent.height - y - bottomInset) : 80)

    radius: isCardMode ? ((typeof appTheme !== "undefined" && appTheme) ? appTheme.px(16) : 16) : 0
    border.color: isPip
                  ? ((typeof appTheme !== "undefined" && appTheme) ? appTheme.borderHover : "#334155")
                  : (isCardMode && typeof appTheme !== "undefined" && appTheme ? appTheme.borderDefault : "transparent")
    border.width: (isPip || isCardMode) ? 1 : 0
    clip: true

    Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on radius { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        anchors.margins: videoContainer.border.width
        fillMode: VideoOutput.PreserveAspectFit
    }
}
