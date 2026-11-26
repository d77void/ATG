// Launcher layout adapted from Utumno (MIT, Copyright 2026 Daniel Azevedo).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "theme"

Window {
    id: launcher

    property string terminal: ""
    property var targetScreen: Qt.application.screens[0]
    readonly property var results: {
        const query = search.text.trim().toLowerCase();
        return Array.from(DesktopEntries.applications.values)
            .filter(app => !app.noDisplay && app.command.length > 0 &&
                (app.name.toLowerCase().includes(query) ||
                 app.genericName.toLowerCase().includes(query) ||
                 app.keywords.some(keyword => keyword.toLowerCase().includes(query))))
            .sort((a, b) => a.name.localeCompare(b.name));
    }

    screen: targetScreen
    x: targetScreen.virtualX + Math.round((targetScreen.width - width) / 2)
    y: targetScreen.virtualY + Math.round((targetScreen.height - height) / 2)
    width: Math.min(560, targetScreen.width - 20)
    height: Math.min(420, targetScreen.height - 20)
    flags: Qt.Popup | Qt.X11BypassWindowManagerHint | Qt.FramelessWindowHint
    title: "ATG Launcher"
    color: "transparent"

    Process {
        command: ["sh", "-c", `
            for candidate in "$TERMINAL" st alacritty kitty xfce4-terminal terminator wezterm xterm; do
                [ -n "$candidate" ] || continue
                executable=$(command -v -- "$candidate") || continue
                [ -f "$executable" ] && [ -x "$executable" ] || continue
                printf '%s\\n' "$executable"
                exit 0
            done
        `]
        running: true
        stdout: SplitParser {
            onRead: line => launcher.terminal = line
        }
    }

    function open(output: var): void {
        if (visible)
            return;
        targetScreen = output;
        search.clear();
        resultsList.currentIndex = 0;
        show();
        // Remapping the popup preserves its previous X11 stacking order.
        raise();
        requestActivate();
        search.forceActiveFocus();
    }

    function toggle(output: var): void {
        if (visible)
            hide();
        else
            open(output);
    }

    function moveSelection(delta: int): void {
        if (results.length)
            resultsList.currentIndex = (resultsList.currentIndex + delta + results.length) % results.length;
    }

    function runInTerminal(command: var, workingDirectory: string): void {
        if (!terminal) {
            console.warn("No terminal found. Set TERMINAL or install a supported terminal.");
            return;
        }
        const executable = terminal.split("/").pop();
        let flags = ["-e"];
        if (executable === "xfce4-terminal" || executable === "terminator")
            flags = ["-x"];
        else if (executable === "wezterm")
            flags = ["start", "--"];
        Quickshell.execDetached({
            command: [terminal, ...flags, ...command],
            workingDirectory: workingDirectory
        });
    }

    function launch(app: var): void {
        if (!app)
            return;
        hide();
        if (app.runInTerminal)
            runInTerminal(app.command, app.workingDirectory);
        else
            app.execute();
    }

    onResultsChanged: resultsList.currentIndex = 0

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.toggle(Qt.application.screens[0]); }
        function open(): void { launcher.open(Qt.application.screens[0]); }
        function close(): void { launcher.hide(); }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Colors.bg
        border.color: Colors.magenta
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: 8
                color: Colors.bgDark
                border.color: search.activeFocus ? Colors.magenta : Colors.muted

                TextInput {
                    id: search

                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    color: Colors.fg
                    selectionColor: Colors.magenta
                    selectedTextColor: Colors.bg
                    font.family: "monospace"
                    font.pixelSize: 14
                    selectByMouse: true
                    focus: true

                    Keys.onEscapePressed: launcher.hide()
                    Keys.onUpPressed: launcher.moveSelection(-1)
                    Keys.onDownPressed: launcher.moveSelection(1)
                    Keys.onTabPressed: launcher.moveSelection(1)
                    Keys.onReturnPressed: launcher.launch(launcher.results[resultsList.currentIndex])
                    Keys.onEnterPressed: launcher.launch(launcher.results[resultsList.currentIndex])

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !search.text
                        text: "Search applications…"
                        color: Colors.fgDark
                        font: search.font
                    }
                }
            }

            ListView {
                id: resultsList

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: launcher.visible ? launcher.results : []
                boundsBehavior: Flickable.StopAtBounds

                onCurrentIndexChanged: {
                    if (currentIndex >= 0)
                        positionViewAtIndex(currentIndex, ListView.Contain);
                }

                delegate: Rectangle {
                    required property int index
                    required property var modelData

                    width: resultsList.width
                    height: 48
                    radius: 8
                    color: index === resultsList.currentIndex ? Colors.blend(Colors.bg, Colors.magenta, 0.20)
                        : rowHover.hovered ? Colors.bgHighlight : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Image {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            source: modelData.icon ? Quickshell.iconPath(modelData.icon, "application-x-executable") : ""
                            sourceSize.width: 28
                            sourceSize.height: 28
                            fillMode: Image.PreserveAspectFit
                        }

                        ColumnLayout {
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                color: Colors.fg
                                font.family: "monospace"
                                font.pixelSize: 14
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: modelData.comment
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                color: Colors.fgDark
                                font.family: "monospace"
                                font.pixelSize: 11
                            }
                        }
                    }

                    HoverHandler { id: rowHover }
                    TapHandler { onTapped: launcher.launch(modelData) }
                }

                Text {
                    anchors.centerIn: parent
                    visible: launcher.results.length === 0
                    text: "No applications found"
                    color: Colors.fgDark
                    font.family: "monospace"
                }
            }
        }
    }
}
