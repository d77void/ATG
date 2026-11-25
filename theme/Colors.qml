pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: colors

    property string wallpaperPath: ""
    property real mix: 0
    property var palette: ({})
    readonly property bool paletteValid: wallpaperPath !== "" && palette.source === wallpaperPath
    readonly property string cacheHome: Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache"
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"

    readonly property color bg: pick("bg", "#1a1b26")
    readonly property color bgDark: pick("bgDark", "#16161e")
    readonly property color bgHighlight: pick("bgHighlight", "#292e42")
    readonly property color fg: pick("fg", "#c0caf5")
    readonly property color fgDark: pick("fgDark", "#a9b1d6")
    readonly property color muted: pick("muted", "#444b6a")
    readonly property color blue: pick("blue", "#7aa2f7")
    readonly property color cyan: pick("cyan", "#7dcfff")
    readonly property color magenta: pick("magenta", "#bb9af7")
    readonly property color red: pick("red", "#f7768e")
    readonly property color yellow: pick("yellow", "#e0af68")
    readonly property color green: pick("green", "#9ece6a")

    function blend(from: color, to: color, amount: real): color {
        return Qt.rgba(from.r + (to.r - from.r) * amount,
                       from.g + (to.g - from.g) * amount,
                       from.b + (to.b - from.b) * amount,
                       from.a + (to.a - from.a) * amount);
    }

    function pick(key: string, base: color): color {
        const value = palette[key];
        if (!paletteValid || mix === 0 || typeof value !== "string" || !/^#[0-9a-f]{6}$/i.test(value))
            return base;
        return blend(base, Qt.color(value), mix);
    }

    function reloadPalette(): void { paletteFile.reload(); }

    function setMix(value: real): void {
        mix = value;
        saveTimer.restart();
    }

    FileView {
        id: paletteFile
        path: colors.cacheHome + "/d77/palette.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoadFailed: colors.palette = ({})
        onLoaded: {
            try {
                const data = JSON.parse(text());
                colors.palette = data && typeof data === "object" ? data : ({});
            } catch (error) {
                colors.palette = ({});
            }
        }
    }

    FileView {
        id: mixFile
        path: colors.configHome + "/d77/theme-mix"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            if (!saveTimer.running && !saveProc.running) {
                const value = Number(text().trim());
                colors.mix = Number.isFinite(value) ? Math.min(1, Math.max(0, value)) : 0;
            }
        }
        onLoadFailed: {
            if (!saveTimer.running && !saveProc.running)
                colors.mix = 0;
        }
    }

    Timer {
        id: saveTimer
        interval: 160
        onTriggered: {
            if (saveProc.running) {
                restart();
            } else {
                saveProc.command = ["bash", Quickshell.shellPath("wallpaper-backend.sh"), "mix", colors.mix.toFixed(2)];
                saveProc.running = true;
            }
        }
    }

    Process {
        id: saveProc
        stderr: SplitParser { onRead: line => console.warn(line) }
        onExited: code => {
            if (code !== 0)
                mixFile.reload();
        }
    }
}
