import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: workspaces

    readonly property string helper: Quickshell.shellPath("atg-ewmh")
    property int count: 0
    property int current: -1
    property var names: []
    property var windowCounts: []
    property var urgent: []

    function isUrgent(index: int): bool {
        return urgent.length === count && urgent[index] === 1;
    }

    function isEmpty(index: int): bool {
        return windowCounts.length === count && windowCounts[index] === 0;
    }

    function select(index: int): void {
        if (index >= 0 && index < count && index !== current)
            Quickshell.execDetached([helper, "select", String(index)]);
    }

    Process {
        command: [workspaces.helper, "watch"]
        running: true
        stderr: SplitParser {
            onRead: line => console.warn(line)
        }
        stdout: SplitParser {
            onRead: line => {
                const state = JSON.parse(line);
                workspaces.names = state.names;
                workspaces.windowCounts = state.windowCounts ?? [];
                workspaces.urgent = state.urgent ?? [];
                workspaces.count = state.count;
                workspaces.current = state.current < state.count ? state.current : -1;
            }
        }
    }
}
