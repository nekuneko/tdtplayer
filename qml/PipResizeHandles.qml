// qml/PipResizeHandles.qml
import QtQuick

Item {
    id: root
    required property var targetWindow

    readonly property int e: 10
    readonly property int c: 16

    readonly property var zones: [
        // 4 bordes
        { x: c, y: 0, w: width - c * 2, h: e, cursor: Qt.SizeVerCursor, edges: Qt.TopEdge },
        { x: c, y: height - e, w: width - c * 2, h: e, cursor: Qt.SizeVerCursor, edges: Qt.BottomEdge },
        { x: 0, y: c, w: e, h: height - c * 2, cursor: Qt.SizeHorCursor, edges: Qt.LeftEdge },
        { x: width - e, y: c, w: e, h: height - c * 2, cursor: Qt.SizeHorCursor, edges: Qt.RightEdge },
        // 4 esquinas
        { x: 0, y: 0, w: c, h: c, cursor: Qt.SizeFDiagCursor, edges: Qt.LeftEdge | Qt.TopEdge },
        { x: width - c, y: 0, w: c, h: c, cursor: Qt.SizeBDiagCursor, edges: Qt.RightEdge | Qt.TopEdge },
        { x: 0, y: height - c, w: c, h: c, cursor: Qt.SizeBDiagCursor, edges: Qt.LeftEdge | Qt.BottomEdge },
        { x: width - c, y: height - c, w: c, h: c, cursor: Qt.SizeFDiagCursor, edges: Qt.RightEdge | Qt.BottomEdge }
    ]

    Repeater {
        model: root.zones
        MouseArea {
            x: modelData.x
            y: modelData.y
            width: modelData.w
            height: modelData.h
            cursorShape: modelData.cursor
            onPressed: root.targetWindow.startSystemResize(modelData.edges)
        }
    }
}
