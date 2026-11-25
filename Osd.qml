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
    property string powerProfile: ""
    property var pending: []
    readonly property string profileLabel: {
        switch (powerProfile) {
        case "performance": return "Performance";
        case "balanced": return "Balanced";
        case "power-saver": return "Power saver";
        default: return "Unknown";
        }
    }
    readonly property color accent: mode === "power"
        ? (powerProfile === "performance" ? Colors.red : powerProfile === "power-saver" ? Colors.green : Colors.blue)
        : (mode === "brightness" ? Colors.yellow : muted ? Colors.red : Colors.magenta)

    screen: Qt.application.screens[0]
    width: 300
    height: 56
    x: screen.virtualX + screen.width - width - 10
    y: screen.virtualY + 58
    flags: Qt.X11BypassWindowManagerHint | Qt.FramelessWindowHint |
        Qt.WindowDoesNotAcceptFocus | Qt.WindowTransparentForInput
    title: "ATG OSD"
    color: "transparent"

    Component.onCompleted: enqueue("power-profile")

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
                const [mode, value, muted] = line.split(" ");
                if (mode === "power-profile" || mode === "power") {
                    osd.powerProfile = value;
                    if (mode === "power-profile")
                        return;
                    osd.level = value === "performance" ? 100 : value === "power-saver" ? 33 : 67;
                } else {
                    osd.level = Number(value);
                }
                osd.mode = mode;
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
        function cyclePowerProfile(): void { osd.enqueue("power-cycle"); }
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
                text: osd.mode === "power"
                    ? (osd.powerProfile === "performance" ? "󰓅" : osd.powerProfile === "power-saver" ? "󰌪" : "󰗑")
                    : (osd.mode === "brightness" ? "󰃠" : osd.muted ? "󰝟" : "󰕾")
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
                text: osd.mode === "power" ? osd.profileLabel : osd.muted ? "Muted" : osd.level + "%"
                color: Colors.fg
                font.family: "monospace"
                font.pixelSize: 13
            }
        }
    }
}
