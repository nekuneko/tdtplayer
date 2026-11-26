// qml/VideoPlayerViewCard.qml
import QtQuick
import QtMultimedia
import QtQuick.Shapes

Item {
    id: videoContainer

    required property bool isPip
    required property bool isCardMode
    required property bool isConfigOpen
    required property bool isSidebarOpen
    required property bool isEpgOpen
    required property real configWidth
    required property real sidebarWidth
    required property real epgHeight
    required property real cardMargin
    property bool isHdrStream: false
    property bool is50TbrStream: false

    property alias videoOutputItem: videoOutput

    function px(v) { return (typeof appTheme !== "undefined" && appTheme) ? appTheme.px(v) : v; }

    readonly property real cardRadius: isCardMode ? px(16) : 0
    readonly property color outerBg: (typeof appTheme !== "undefined" && appTheme) ? appTheme.bgCanvas : "#1E293B"

    anchors.fill: parent
    anchors.leftMargin: isCardMode ? (isConfigOpen ? configWidth : cardMargin) : 0
    anchors.rightMargin: isCardMode ? (isSidebarOpen ? sidebarWidth : cardMargin) : 0
    anchors.topMargin: isCardMode ? cardMargin : 0
    anchors.bottomMargin: isCardMode ? (cardMargin + (isEpgOpen ? (epgHeight + cardMargin) : 0)) : 0

    Behavior on anchors.leftMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on anchors.rightMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on anchors.topMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on anchors.bottomMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        anchors.margins: borderOverlay.border.width
        fillMode: VideoOutput.PreserveAspectFit
        visible: true
    }

    VideoShaderPipeline {
        videoOutput: videoOutput
        isHdrStream: videoContainer.isHdrStream
        is50TbrStream: videoContainer.is50TbrStream
    }

    // Capa de recorte y borde con layer.enabled: true para forzar composición RHI encima del VideoOutput
    Item {
        anchors.fill: parent
        z: 10
        visible: videoContainer.isPip || videoContainer.isCardMode
        layer.enabled: true
        layer.smooth: true

        Shape {
            id: cornerShape
            anchors.fill: parent
            visible: videoContainer.isCardMode && videoContainer.cardRadius > 0

            readonly property real r: Math.min(videoContainer.cardRadius, width * 0.5, height * 0.5)
            readonly property real w: width
            readonly property real h: height

            ShapePath {
                strokeWidth: 0
                fillColor: videoContainer.outerBg
                startX: 0; startY: cornerShape.r
                PathArc { x: cornerShape.r; y: 0; radiusX: cornerShape.r; radiusY: cornerShape.r; direction: PathArc.Clockwise }
                PathLine { x: 0; y: 0 }
                PathLine { x: 0; y: cornerShape.r }
            }
            ShapePath {
                strokeWidth: 0
                fillColor: videoContainer.outerBg
                startX: cornerShape.w - cornerShape.r; startY: 0
                PathArc { x: cornerShape.w; y: cornerShape.r; radiusX: cornerShape.r; radiusY: cornerShape.r; direction: PathArc.Clockwise }
                PathLine { x: cornerShape.w; y: 0 }
                PathLine { x: cornerShape.w - cornerShape.r; y: 0 }
            }
            ShapePath {
                strokeWidth: 0
                fillColor: videoContainer.outerBg
                startX: cornerShape.w; startY: cornerShape.h - cornerShape.r
                PathArc { x: cornerShape.w - cornerShape.r; y: cornerShape.h; radiusX: cornerShape.r; radiusY: cornerShape.r; direction: PathArc.Clockwise }
                PathLine { x: cornerShape.w; y: cornerShape.h }
                PathLine { x: cornerShape.w; y: cornerShape.h - cornerShape.r }
            }
            ShapePath {
                strokeWidth: 0
                fillColor: videoContainer.outerBg
                startX: cornerShape.r; startY: cornerShape.h
                PathArc { x: 0; y: cornerShape.h - cornerShape.r; radiusX: cornerShape.r; radiusY: cornerShape.r; direction: PathArc.Clockwise }
                PathLine { x: 0; y: cornerShape.h }
                PathLine { x: cornerShape.r; y: cornerShape.h }
            }
        }

        Rectangle {
            id: borderOverlay
            anchors.fill: parent
            color: "transparent"
            radius: videoContainer.cardRadius
            border.color: videoContainer.isPip
                          ? ((typeof appTheme !== "undefined" && appTheme) ? appTheme.borderHover : "#334155")
                          : ((typeof appTheme !== "undefined" && appTheme) ? appTheme.borderDefault : "#1E293B")
            border.width: 1
        }
    }
}
