import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: weather

    property string summary: "…"
    property string details: "Loading weather"
    readonly property string location: Quickshell.env("ATG_WEATHER_LOCATION") || ""

    Process {
        id: request
        command: [
            "curl", "--fail", "--silent", "--max-time", "10", "--user-agent", "curl/7.0",
            "https://wttr.in/" + encodeURIComponent(weather.location) + "?m&format=%c%7C%t%7C%l"
        ]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const [condition, temperature, place] = text.trim().split("|").map(part => part.trim());
                if (condition && /^[+-]?\d+°C$/.test(temperature) && place) {
                    weather.summary = condition + " " + temperature;
                    weather.details = place + "  " + weather.summary;
                }
            }
        }

        onExited: {
            if (weather.summary === "…") {
                weather.summary = "☁ —";
                weather.details = "Weather unavailable";
            }
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: true
        onTriggered: request.running = true
    }
}
