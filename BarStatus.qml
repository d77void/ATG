import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.UPower

Scope {
    id: status

    property int cpu: -1
    property int memory: -1
    property int volume: -1
    property bool muted: false
    property real previousIdle: -1
    property real previousTotal: -1

    readonly property var networkDevice: Networking.devices.values.find(device =>
        device.connected && (device.type === DeviceType.Wired || device.type === DeviceType.Wifi))
    readonly property bool wired: networkDevice?.type === DeviceType.Wired
    readonly property var wifi: networkDevice?.type === DeviceType.Wifi
        ? networkDevice.networks.values.find(network => network.connected) : null
    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool hasBattery: batteryDevice?.isLaptopBattery ?? false
    readonly property int battery: hasBattery ? Math.round(batteryDevice.percentage * 100) : 0
    readonly property bool charging: hasBattery && batteryDevice.state === UPowerDeviceState.Charging
    readonly property string batterySummary: {
        if (!hasBattery)
            return "";
        if (charging)
            return batteryDevice.timeToFull > 0 ? duration(batteryDevice.timeToFull) + " until full" : "Charging";
        if (batteryDevice.state === UPowerDeviceState.Discharging)
            return batteryDevice.timeToEmpty > 0 ? duration(batteryDevice.timeToEmpty) + " remaining" : "On battery";
        return UPowerDeviceState.toString(batteryDevice.state).replace(/([a-z])([A-Z])/g, "$1 $2");
    }

    function duration(seconds: real): string {
        const total = Math.round(seconds / 60);
        const hours = Math.floor(total / 60);
        return hours > 0 ? hours + "h " + total % 60 + "min" : total + "min";
    }

    // Sample the Linux counters once for all bars.
    FileView {
        id: cpuFile
        path: "/proc/stat"
        onLoaded: {
            const ticks = text().split("\n")[0].trim().split(/\s+/).slice(1, 9).map(Number);
            if (ticks.length < 8)
                return;
            const idle = ticks[3] + ticks[4];
            const total = ticks.reduce((sum, tick) => sum + tick, 0);
            const elapsed = total - status.previousTotal;
            if (status.previousTotal >= 0 && elapsed > 0)
                status.cpu = Math.round(100 * Math.max(0, Math.min(1, 1 - (idle - status.previousIdle) / elapsed)));
            status.previousIdle = idle;
            status.previousTotal = total;
        }
    }

    FileView {
        id: memoryFile
        path: "/proc/meminfo"
        onLoaded: {
            const data = text();
            const total = Number(data.match(/^MemTotal:\s+(\d+)/m)?.[1]);
            const available = Number(data.match(/^MemAvailable:\s+(\d+)/m)?.[1]);
            if (total > 0 && Number.isFinite(available))
                status.memory = Math.round(100 * (1 - available / total));
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuFile.reload();
            memoryFile.reload();
            if (!volumeEvents.running)
                volumeEvents.running = true;
        }
    }

    Process {
        id: volumeEvents
        command: ["pactl", "subscribe"]
        environment: ({ LC_ALL: "C" })
        running: true
        onStarted: volumeRefresh.restart()
        stdout: SplitParser {
            onRead: line => {
                if (line.includes(" on sink ") || line.includes(" on server "))
                    volumeRefresh.restart();
            }
        }
    }

    Timer {
        id: volumeRefresh
        interval: 80
        onTriggered: {
            if (volumeRead.running)
                restart();
            else
                volumeRead.running = true;
        }
    }

    Process {
        id: volumeRead
        command: ["sh", Quickshell.shellPath("osd-backend.sh"), "volume"]
        stdout: SplitParser {
            onRead: line => {
                const [, level, muted] = line.split(" ");
                status.volume = Number(level);
                status.muted = muted === "yes";
            }
        }
        onExited: code => {
            if (code !== 0)
                status.volume = -1;
        }
    }
}
