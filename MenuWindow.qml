import QtQuick

Window {
    id: menuWindow

    property bool activationPending: false

    flags: Qt.Popup | Qt.X11BypassWindowManagerHint | Qt.FramelessWindowHint
    color: "transparent"

    function showMenu(): void {
        activationPending = true;
        show();
    }

    onFrameSwapped: {
        if (!activationPending)
            return;
        activationPending = false;
        // Let X11 process the first frame's window events before taking focus.
        activateAfterFrame.start();
    }

    onVisibleChanged: {
        if (!visible) {
            activationPending = false;
            activateAfterFrame.stop();
        }
    }

    Timer {
        id: activateAfterFrame
        interval: 0
        onTriggered: if (menuWindow.visible) menuWindow.requestActivate()
    }
}
