import QtQuick
import Quickshell
import Quickshell.Io
import "theme"

Scope {
    id: wallpaper

    readonly property string directory: Quickshell.env("ATG_WALLPAPER_DIR") || Quickshell.env("HOME") + "/Wallpaper"
    readonly property bool busy: runner.running
    readonly property string screenLayout: Array.from(Qt.application.screens).map(screen =>
        [screen.virtualX, screen.virtualY, screen.width, screen.height].join(",")).join(";")
    property string currentPath: ""
    property string message: ""
    property var pending: null

    function run(action: string, path: string): void {
        if (runner.running) {
            // Only the latest selection matters while the current palette is being generated.
            pending = [action, path];
            return;
        }
        message = "";
        runner.command = ["bash", Quickshell.shellPath("wallpaper-backend.sh"), action, path];
        runner.running = true;
    }

    Component.onCompleted: {
        backdropResize.stop();
        run("restore", "");
    }
    onScreenLayoutChanged: {
        if (currentPath === "")
            backdropResize.restart();
    }

    Timer {
        id: backdropResize
        interval: 250
        onTriggered: {
            if (wallpaper.currentPath !== "")
                return;
            if (wallpaper.busy)
                restart();
            else
                wallpaper.run("restore", "");
        }
    }

    Process {
        id: runner

        stdout: SplitParser {
            onRead: line => wallpaper.currentPath = JSON.parse(line).path
        }
        stderr: StdioCollector { id: errors }
        onExited: code => {
            Colors.reloadPalette();
            if (code !== 0 || errors.text.trim())
                wallpaper.message = errors.text.trim() || "Wallpaper operation failed";
            if (wallpaper.pending !== null) {
                const [action, path] = wallpaper.pending;
                wallpaper.pending = null;
                wallpaper.run(action, path);
            }
        }
    }
}
