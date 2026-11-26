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

    // Recorta EXACTAMENTE el rectángulo activo del vídeo (sin bandas negras) a su resolución nativa
    ShaderEffectSource {
        id: videoTextureSource
        sourceItem: videoOutput
        sourceRect: videoOutput.contentRect
        hideSource: true
        live: true
        visible: false
        smooth: false
        textureSize: (videoOutput.sourceRect.width > 0 && videoOutput.sourceRect.height > 0)
                     ? Qt.size(videoOutput.sourceRect.width, videoOutput.sourceRect.height)
                     : Qt.size(0, 0)
    }

    readonly property real videoTexHeight: videoOutput.sourceRect.height > 0 ? videoOutput.sourceRect.height : 1080
    readonly property real videoTexWidth: videoOutput.sourceRect.width > 0 ? videoOutput.sourceRect.width : 1920
    readonly property bool hasActiveVideo: videoOutput.contentRect.width > 0
    readonly property bool isHdrSignal: videoContainer.isHdrStream
    readonly property bool isUhdSdrSignal: (!isHdrSignal && Math.round(videoTexHeight) === 2160)
    readonly property bool isInterlacedSignal: (!isHdrSignal && (Math.round(videoTexHeight) === 1080 || Math.round(videoTexHeight) === 576))
    readonly property bool isPassthroughSignal: (!isHdrSignal && !isUhdSdrSignal && !isInterlacedSignal)

    // Referencia geométrica única para ScreenshotHelper (Windows y Linux)
    Item {
        id: gpuVideoPipeline
        objectName: "gpuVideoPipeline"
        x: videoOutput.x + videoOutput.contentRect.x
        y: videoOutput.y + videoOutput.contentRect.y
        width: videoOutput.contentRect.width
        height: videoOutput.contentRect.height
    }

    // 1. Shader dedicado para emisiones HDR HLG (La 1 UHD, La 2 UHD)
    ShaderEffect {
        anchors.fill: gpuVideoPipeline
        visible: videoContainer.hasActiveVideo && videoContainer.isHdrSignal
        property variant source: videoTextureSource
        property real texHeight: videoContainer.videoTexHeight
        property real texWidth: videoContainer.videoTexWidth
        fragmentShader: "shaders/hdr_hlg_uhd.frag.qsb"
    }

    // 2. Shader dedicado para emisiones 4K UHD SDR BT.709 (A3 UHD, Telecinco UHD)
    ShaderEffect {
        anchors.fill: gpuVideoPipeline
        visible: videoContainer.hasActiveVideo && videoContainer.isUhdSdrSignal
        property variant source: videoTextureSource
        property real texHeight: videoContainer.videoTexHeight
        property real texWidth: videoContainer.videoTexWidth
        fragmentShader: "shaders/uhd_sdr_bt709.frag.qsb"
    }

    // 3. Shader dedicado para emisiones entrelazadas 1080i / 576i (La 1 HD, Teledeporte, etc.)
    ShaderEffect {
        anchors.fill: gpuVideoPipeline
        visible: videoContainer.hasActiveVideo && videoContainer.isInterlacedSignal
        property variant source: videoTextureSource
        property real texHeight: videoContainer.videoTexHeight
        property real texWidth: videoContainer.videoTexWidth
        fragmentShader: "shaders/deinterlace_1080i.frag.qsb"
    }

    // 4. Shader passthrough 1:1 para señales progresivas SDR (720p / 1080p)
    ShaderEffect {
        anchors.fill: gpuVideoPipeline
        visible: videoContainer.hasActiveVideo && videoContainer.isPassthroughSignal
        property variant source: videoTextureSource
        property real texHeight: videoContainer.videoTexHeight
        property real texWidth: videoContainer.videoTexWidth
        fragmentShader: "shaders/passthrough_sdr.frag.qsb"
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
