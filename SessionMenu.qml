import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "theme"

Window {
    id: menu

    property var targetScreen: Qt.application.screens[0]
    property int selected: 0
    property string error: ""
    property string actionName: ""
    readonly property var actions: [
        { label: "Lock", icon: "󰌾", color: Colors.blue, command: ["amorphis", "--backend", "x11"] },
        { label: "Suspend", icon: "󰒲", color: Colors.yellow, command: ["loginctl", "suspend"] },
        { label: "Restart", icon: "󰑓", color: Colors.yellow, command: ["loginctl", "reboot"] },
        { label: "Shut down", icon: "󰐥", color: Colors.red, command: ["loginctl", "poweroff"] },
        { label: "Log out", icon: "󰍃", color: Colors.red,
          command: ["loginctl", "terminate-session", Quickshell.env("XDG_SESSION_ID") || "self"] }
    ]

    screen: targetScreen
    x: targetScreen.virtualX + Math.round((targetScreen.width - width) / 2)
    y: targetScreen.virtualY + Math.round((targetScreen.height - height) / 2)
    width: 220
    height: choices.implicitHeight + 20
    flags: Qt.Popup | Qt.X11BypassWindowManagerHint | Qt.FramelessWindowHint
    title: "ATG Session"
    color: "transparent"

    function openAt(output: var): void {
        if (visible)
            return;
        targetScreen = output;
        show();
        requestActivate();
        sessionBox.forceActiveFocus();
    }

    function toggle(output: var): void {
        if (visible) {
            hide();
        } else {
            selected = 0;
            error = "";
            openAt(output);
        }
    }

    function activate(index: int): void {
        if (sessionCommand.running)
            return;
        const action = actions[index];
        actionName = action.label;
        error = "";
        hide();
        sessionCommand.command = action.command;
        // Release the popup's keyboard and pointer grabs before starting the locker.
        Qt.callLater(() => sessionCommand.running = true);
    }

    Process {
        id: sessionCommand

        stderr: StdioCollector { id: commandError }
        onExited: code => {
            if (code !== 0) {
                menu.error = menu.actionName + " failed";
                const message = commandError.text.trim();
                if (message)
                    menu.error += "\n" + message;
                menu.openAt(menu.targetScreen);
            }
        }
    }

    IpcHandler {
        target: "session"
        function open(): void {
            if (!menu.visible)
                menu.toggle(Qt.application.screens[0]);
        }
        function close(): void { menu.hide(); }
        function toggle(): void { menu.toggle(Qt.application.screens[0]); }
    }

    Rectangle {
        id: sessionBox

        anchors.fill: parent
        radius: 12
        color: Colors.bgDark
        border.color: Colors.red
        border.width: 2
        focus: true

        Keys.onEscapePressed: menu.hide()
        Keys.onUpPressed: menu.selected = (menu.selected - 1 + menu.actions.length) % menu.actions.length
        Keys.onDownPressed: menu.selected = (menu.selected + 1) % menu.actions.length
        Keys.onReturnPressed: menu.activate(menu.selected)
        Keys.onEnterPressed: menu.activate(menu.selected)

        ColumnLayout {
            id: choices

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 4

            Repeater {
                model: menu.actions

                Rectangle {
                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: 6
                    color: index === menu.selected ? Qt.alpha(modelData.color, 0.2) : "transparent"

                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.label
                    Accessible.onPressAction: menu.activate(index)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        Text {
                            Layout.preferredWidth: 24
                            text: modelData.icon
                            color: modelData.color
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 22
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.label
                            color: Colors.fg
                            font.family: "monospace"
                            font.pixelSize: 14
                        }
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: if (hovered) menu.selected = index
                    }
                    TapHandler { onTapped: menu.activate(index) }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: !!menu.error
                text: menu.error
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                color: Colors.red
                font.pixelSize: 12
            }
        }
    }
}
