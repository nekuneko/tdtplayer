// qml/VideoShaderPipeline.qml
import QtQuick
import QtMultimedia

Item {
    id: gpuVideoPipeline
    objectName: "gpuVideoPipeline"

    required property VideoOutput videoOutput
    required property bool isHdrStream
    required property bool is50TbrStream

    x: videoOutput.x + videoOutput.contentRect.x
    y: videoOutput.y + videoOutput.contentRect.y
    width: videoOutput.contentRect.width
    height: videoOutput.contentRect.height

    ShaderEffectSource {
        id: videoTextureSource
        sourceItem: gpuVideoPipeline.videoOutput
        sourceRect: gpuVideoPipeline.videoOutput.contentRect
        hideSource: true
        live: true
        visible: false
        smooth: Qt.platform.os !== "linux"
        mipmap: Qt.platform.os !== "linux"
        textureSize: (gpuVideoPipeline.videoOutput.sourceRect.width > 0 && gpuVideoPipeline.videoOutput.sourceRect.height > 0)
                     ? Qt.size(gpuVideoPipeline.videoOutput.sourceRect.width, gpuVideoPipeline.videoOutput.sourceRect.height)
                     : Qt.size(0, 0)
    }

    readonly property real videoTexHeight: videoOutput.sourceRect.height > 0 ? videoOutput.sourceRect.height : 1080
    readonly property real videoTexWidth: videoOutput.sourceRect.width > 0 ? videoOutput.sourceRect.width : 1920
    readonly property bool hasActiveVideo: videoOutput.contentRect.width > 0
    readonly property bool isHdrSignal: gpuVideoPipeline.isHdrStream
    readonly property bool is1080Or576: (!isHdrSignal && (Math.round(videoTexHeight) === 1080 || Math.round(videoTexHeight) === 576))
    readonly property bool isInterlaced50TbrSignal: (is1080Or576 && gpuVideoPipeline.is50TbrStream)
    readonly property bool isInterlaced25TbrSignal: (is1080Or576 && !gpuVideoPipeline.is50TbrStream)
    readonly property bool isPassthroughSignal: (!isHdrSignal && !is1080Or576)

    // 1. HDR HLG (La 1 UHD, La 2 UHD)
    ShaderEffect {
        anchors.fill: parent
        visible: gpuVideoPipeline.hasActiveVideo && gpuVideoPipeline.isHdrSignal
        property variant source: videoTextureSource
        property real texHeight: gpuVideoPipeline.videoTexHeight
        property real texWidth: gpuVideoPipeline.videoTexWidth
        fragmentShader: "shaders/hdr_hlg_uhd.frag.qsb"
    }

    // 2A. Entrelazado 1080 a 50 tbr (tdp HD, etc.)
    ShaderEffect {
        anchors.fill: parent
        visible: gpuVideoPipeline.hasActiveVideo && gpuVideoPipeline.isInterlaced50TbrSignal
        property variant source: videoTextureSource
        property real texHeight: gpuVideoPipeline.videoTexHeight
        property real texWidth: gpuVideoPipeline.videoTexWidth
        fragmentShader: "shaders/deinterlace_1080i_50tbr.frag.qsb"
    }

    // 2B. Entrelazado 1080i / 576i a 25 tbr (Cuatro HD, etc.)
    ShaderEffect {
        anchors.fill: parent
        visible: gpuVideoPipeline.hasActiveVideo && gpuVideoPipeline.isInterlaced25TbrSignal
        property variant source: videoTextureSource
        property real texHeight: gpuVideoPipeline.videoTexHeight
        property real texWidth: gpuVideoPipeline.videoTexWidth
        fragmentShader: "shaders/deinterlace_1080i_25tbr.frag.qsb"
    }

    // 3. Passthrough 1:1 SDR progresivo (720p, 1080p y 4K UHD BT.709 como A3 UHD y Telecinco UHD)
    ShaderEffect {
        anchors.fill: parent
        visible: gpuVideoPipeline.hasActiveVideo && gpuVideoPipeline.isPassthroughSignal
        property variant source: videoTextureSource
        property real texHeight: gpuVideoPipeline.videoTexHeight
        property real texWidth: gpuVideoPipeline.videoTexWidth
        fragmentShader: "shaders/passthrough_sdr.frag.qsb"
    }
}
