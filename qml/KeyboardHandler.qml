// KeyboardHandler.qml
import QtQuick

Item {
    id: root
    anchors.fill: parent
    focus: true

    property var controller: null
    property var window: null
    property var channelNumPopup: null

    Keys.onUpPressed: if (controller) controller.playChannel(controller.currentChannelIndex - 1)
    Keys.onDownPressed: if (controller) controller.playChannel(controller.currentChannelIndex + 1)
    
    Keys.onLeftPressed: if (controller) controller.changeVolume(-5)
    Keys.onRightPressed: if (controller) controller.changeVolume(5)

    Keys.onPressed: (event) => {
        if (!controller || !window || !channelNumPopup) return;

        if (event.key === Qt.Key_Space) {
            controller.togglePlayback();
            event.accepted = true;
        }
        else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !channelNumPopup.opened) {
            controller.forceResume();
            event.accepted = true;
        }
        else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9 && !channelNumPopup.opened) {
            channelNumPopup.openWithText(event.text);
            event.accepted = true;
        }
        else if (event.key === Qt.Key_Escape && controller.isFullScreen && !channelNumPopup.opened) {
            if (controller.sidebar && controller.sidebar.sidebarForceOpen) {
                controller.sidebar.sidebarForceOpen = false;
            } else {
                window.visibility = Window.Windowed;
                controller.isFullScreen = false;
            }
            event.accepted = true;
        }
    }
}
