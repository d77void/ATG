import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: workspaces

    readonly property string helper: Quickshell.shellPath("atg-ewmh")
    property int count: 0
    property int current: -1
    property var names: []

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
                workspaces.count = state.count;
                workspaces.current = state.current < state.count ? state.current : -1;
            }
        }
    }
}
