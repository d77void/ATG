import QtQuick
import Quickshell
import "theme"

Scope {
    id: bar

    required property EwmhWorkspaces workspaces
    required property BarStatus status
    required property string clockText
    required property Weather weather
    property bool launcherOpen: false
    property bool sessionOpen: false
    property bool osdOpen: false
    required property string profileLabel

    signal launcherRequested
    signal sessionRequested
    signal volumeRequested
    signal volumeAdjusted(int steps)
    signal networkRequested
    signal monitorRequested(string mode)
    signal profileRequested
    signal profileCycleRequested

    readonly property int gap: 10
    readonly property bool compact: width < 760
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    readonly property color background: Colors.bg
    readonly property color highlight: Colors.bgHighlight
    readonly property color foreground: Colors.fg
    readonly property color secondary: Colors.fgDark
    readonly property color separator: Colors.muted
    readonly property color blue: Colors.blue
    readonly property color red: Colors.red
    readonly property color magenta: Colors.magenta

    required property var screen
    readonly property int topGap: 8
    readonly property int x: screen.virtualX + gap
    readonly property int y: screen.virtualY + topGap
    readonly property int width: screen.width - 2 * gap
    readonly property int height: 40

    readonly property bool useDock: Quickshell.env("XDG_CURRENT_DESKTOP") === "whiplash"

    Loader {
        id: dockWindow
        active: bar.useDock

        sourceComponent: PanelWindow {
            screen: Quickshell.screens.find(output => output.name === bar.screen.name) ?? null
            anchors { top: true; left: true; right: true }
            margins { top: bar.topGap; left: bar.gap; right: bar.gap }
            implicitHeight: bar.height
            exclusiveZone: bar.height + bar.topGap
            focusable: false
            color: "transparent"
        }
    }

    Window {
        id: legacyBar
        screen: bar.screen
        x: bar.x
        y: bar.y
        width: bar.width
        height: bar.height
        title: "ATG"
        // wmd77 provides its own reserve_top and tiles ordinary dock windows.
        flags: Qt.X11BypassWindowManagerHint | Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus
        visible: !bar.useDock
        color: "transparent"

        Component.onCompleted: {
            if (visible)
                Qt.callLater(() => legacyBar.lower())
        }
    }

    component Label: Text {
        textFormat: Text.PlainText
        color: bar.foreground
        font.family: bar.iconFont
        font.pixelSize: 13
        anchors.verticalCenter: parent.verticalCenter
    }

    component MetricButton: Label {
        readonly property bool hovered: pointer.hovered
        signal clicked

        color: hovered ? bar.magenta : bar.foreground
        Accessible.role: Accessible.Button
        Accessible.onPressAction: clicked()
        HoverHandler { id: pointer; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: clicked() }
    }

    Rectangle {
        parent: bar.useDock ? (dockWindow.item?.contentItem ?? null) : legacyBar.contentItem
        anchors.fill: parent
        radius: 12
        color: bar.background

        Rectangle {
            id: launcherButton

            anchors.left: parent.left
            anchors.leftMargin: bar.gap
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            height: 30
            radius: 7
            color: launcherHover.hovered || bar.launcherOpen
                ? Qt.lighter(bar.magenta, 1.2) : bar.magenta

            Accessible.role: Accessible.Button
            Accessible.name: "Open application launcher"
            Accessible.onPressAction: bar.launcherRequested()

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰍜"
                color: bar.background
            }

            HoverHandler { id: launcherHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: bar.launcherRequested() }
        }

        Rectangle {
            id: workspaceDivider

            anchors.left: launcherButton.right
            anchors.leftMargin: bar.gap
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 22
            color: bar.separator
        }

        Flickable {
            id: workspaceStrip

            anchors.left: workspaceDivider.right
            anchors.leftMargin: bar.gap
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, centerRow.x - x - bar.gap)
            height: 26
            clip: true
            contentWidth: workspaceRow.width
            contentHeight: height
            interactive: contentWidth > width
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: workspaceRow
                spacing: 6

                Repeater {
                    model: bar.workspaces.count

                    Rectangle {
                        id: workspace

                        required property int index
                        readonly property bool selected: bar.workspaces.current === index
                        readonly property bool urgent: bar.workspaces.isUrgent(index)
                        readonly property string label: bar.workspaces.names[index] || String(index + 1)

                        width: Math.max(26, Math.min(workspaceText.implicitWidth + 12, 100))
                        height: 26
                        radius: 6
                        color: selected ? bar.blue : urgent ? bar.red
                            : workspaceHover.hovered ? bar.separator : bar.highlight
                        opacity: !selected && !urgent && bar.workspaces.isEmpty(index) ? 0.4 : 1

                        Accessible.role: Accessible.Button
                        Accessible.name: "Workspace " + label
                        Accessible.onPressAction: bar.workspaces.select(index)

                        Label {
                            id: workspaceText

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: workspace.label
                            color: workspace.selected || workspace.urgent ? bar.background : bar.secondary
                            font.pixelSize: 14
                        }

                        HoverHandler { id: workspaceHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: bar.workspaces.select(workspace.index) }
                    }
                }
            }
        }

        Row {
            id: centerRow

            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height
            spacing: bar.gap * 2

            Label {
                id: weatherLabel

                visible: bar.width >= 460
                text: bar.weather.summary

                HoverHandler { id: weatherHover }
            }

            Label { text: bar.clockText }
        }

        Rectangle {
            id: sessionButton

            anchors.right: parent.right
            anchors.rightMargin: bar.gap
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            height: 30
            radius: 7
            color: sessionHover.hovered || bar.sessionOpen ? Colors.red : Colors.blend(Colors.bg, Colors.red, 0.30)

            Accessible.role: Accessible.Button
            Accessible.name: "Open session menu"
            Accessible.onPressAction: bar.sessionRequested()

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "⏻"
                color: sessionHover.hovered || bar.sessionOpen ? bar.background : Colors.red
                font.pixelSize: 16
            }

            HoverHandler { id: sessionHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: bar.sessionRequested() }
        }

        Rectangle {
            id: sessionDivider

            anchors.right: sessionButton.left
            anchors.rightMargin: bar.gap
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 22
            color: bar.separator
        }

        Item {
            id: statusArea

            anchors.left: centerRow.right
            anchors.leftMargin: bar.gap
            anchors.right: sessionDivider.left
            anchors.rightMargin: bar.gap
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            clip: true

            Row {
                id: metrics

                anchors.right: parent.right
                height: parent.height
                spacing: bar.compact ? 12 : 26

                MetricButton {
                    visible: bar.width >= 700 && bar.status.cpu >= 0
                    text: "󰻠 " + bar.status.cpu + "%"
                    Accessible.name: "Open CPU monitor"
                    onClicked: bar.monitorRequested("cpu")
                }

                MetricButton {
                    visible: bar.width >= 700 && bar.status.memory >= 0
                    text: "󰍛 " + bar.status.memory + "%"
                    Accessible.name: "Open memory monitor"
                    onClicked: bar.monitorRequested("memory")
                }

                MetricButton {
                    visible: bar.status.volume >= 0
                    text: (bar.status.muted ? "󰝟 " : "󰕾 ") + bar.status.volume + "%"
                    Accessible.name: "Toggle mute"
                    onClicked: bar.volumeRequested()

                    DragHandler {
                        id: volumeDrag
                        target: null
                        xAxis.enabled: false
                        property real handledY: 0
                        onActiveChanged: handledY = 0
                        onActiveTranslationChanged: {
                            if (!active)
                                return;
                            const steps = Math.trunc((handledY - activeTranslation.y) / 12);
                            if (steps === 0)
                                return;
                            handledY -= steps * 12;
                            bar.volumeAdjusted(steps);
                        }
                    }
                }

                MetricButton {
                    visible: bar.width >= 400
                    width: Math.min(implicitWidth, 200)
                    elide: Text.ElideRight
                    Accessible.name: "Open NetworkManager in a terminal"
                    onClicked: bar.networkRequested()
                    text: {
                        if (bar.status.wired)
                            return bar.compact ? "󰈀" : "󰈀 Wired";
                        const network = bar.status.wifi;
                        if (network)
                            return bar.compact ? "󰤨" : "󰤨 " + network.name + " " + Math.round(network.signalStrength * 100) + "%";
                        if (bar.status.networkDevice)
                            return bar.compact ? "󰤨" : "󰤨 Wi-Fi";
                        return bar.compact ? "󰤭" : "󰤭 Offline";
                    }
                }

                MetricButton {
                    id: batteryLabel

                    visible: bar.status.hasBattery
                    text: (bar.status.charging ? "󰂄 " : "󰁹 ") + bar.status.battery + "%"
                    color: hovered ? bar.magenta : bar.status.charging ? Colors.green
                        : bar.status.battery < 20 ? Colors.red : bar.foreground
                    Accessible.name: "Cycle power profile"
                    onHoveredChanged: if (hovered) bar.profileRequested()
                    onClicked: bar.profileCycleRequested()
                }
            }
        }
    }

    BarTooltip {
        anchorCenter: centerRow.x + weatherLabel.x + weatherLabel.width / 2
        visible: weatherHover.hovered && !bar.launcherOpen && !bar.sessionOpen
        title: "ATG Weather"
        text: bar.weather.details
    }

    BarTooltip {
        anchorCenter: statusArea.x + metrics.x + batteryLabel.x + batteryLabel.width / 2
        visible: batteryLabel.hovered && !bar.launcherOpen && !bar.sessionOpen && !bar.osdOpen
        title: "ATG Battery"
        text: bar.status.batterySummary + "\nPower profile: " + bar.profileLabel
    }

    component BarTooltip: Window {
        id: tip

        required property real anchorCenter
        required property string text

        screen: bar.screen
        x: Math.max(screen.virtualX + bar.gap, Math.min(
            bar.x + anchorCenter - width / 2,
            screen.virtualX + screen.width - width - bar.gap))
        y: bar.y + bar.height + bar.gap
        width: Math.min(tipLabel.implicitWidth + 24, screen.width - 2 * bar.gap)
        height: tipLabel.implicitHeight + 16
        flags: Qt.ToolTip | Qt.X11BypassWindowManagerHint | Qt.WindowDoesNotAcceptFocus |
            Qt.WindowTransparentForInput
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: bar.background
            border.color: bar.separator

            Label {
                id: tipLabel

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                elide: Text.ElideRight
                text: tip.text
            }
        }
    }
}
