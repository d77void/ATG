// Volume and brightness overlay adapted from Utumno (MIT, Copyright 2026 Daniel Azevedo).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "theme"

Window {
    id: osd

    property int level: 0
    property bool muted: false
    property string mode: "volume"
    property var pending: []
    readonly property color accent: mode === "brightness" ? Colors.yellow : muted ? Colors.red : Colors.magenta

    screen: Qt.application.screens[0]
    width: 300
    height: 56
    x: screen.virtualX + screen.width - width - 10
    y: screen.virtualY + 58
    flags: Qt.X11BypassWindowManagerHint | Qt.FramelessWindowHint |
        Qt.WindowDoesNotAcceptFocus | Qt.WindowTransparentForInput
    title: "ATG OSD"
    color: "transparent"

    function enqueue(operation: string): void {
        pending.push(operation);
        if (!backend.running)
            next();
    }

    function next(): void {
        if (pending.length) {
            backend.command = ["sh", Quickshell.shellPath("osd-backend.sh"), pending.shift()];
            backend.running = true;
        }
    }

    Process {
        id: backend

        stdout: SplitParser {
            onRead: line => {
                const [mode, level, muted] = line.split(" ");
                osd.mode = mode;
                osd.level = Number(level);
                osd.muted = muted === "yes";
                osd.show();
                osd.raise();
                dismiss.restart();
            }
        }
        stderr: SplitParser { onRead: line => console.warn(line) }
        onExited: osd.next()
    }

    Timer {
        id: dismiss
        interval: 2500
        onTriggered: osd.hide()
    }

    IpcHandler {
        target: "osd"
        function volumeUp(): void { osd.enqueue("volume-up"); }
        function volumeDown(): void { osd.enqueue("volume-down"); }
        function volumeMuteToggle(): void { osd.enqueue("volume-mute"); }
        function showVolume(): void { osd.enqueue("volume"); }
        function brightnessUp(): void { osd.enqueue("brightness-up"); }
        function brightnessDown(): void { osd.enqueue("brightness-down"); }
        function showBrightness(): void { osd.enqueue("brightness"); }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Colors.bg
        border.color: Colors.muted

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 14

            Text {
                text: osd.mode === "brightness" ? "󰃠" : osd.muted ? "󰝟" : "󰕾"
                color: osd.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 22
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 8
                radius: height / 2
                color: Colors.bgHighlight

                Rectangle {
                    width: parent.width * Math.min(1, osd.level / 100)
                    height: parent.height
                    radius: parent.radius
                    color: osd.accent
                }
            }

            Text {
                text: osd.muted ? "Muted" : osd.level + "%"
                color: Colors.fg
                font.family: "monospace"
                font.pixelSize: 13
            }
        }
    }
}
