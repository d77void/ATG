import QtQuick
import "theme"

Window {
    id: bar

    required property EwmhWorkspaces workspaces
    required property BarStatus status
    required property string clockText
    required property Weather weather
    property bool launcherOpen: false
    property bool sessionOpen: false

    signal launcherRequested
    signal sessionRequested
    signal volumeRequested

    readonly property int gap: 10
    readonly property bool compact: width < 760
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    readonly property color background: Colors.bg
    readonly property color highlight: Colors.bgHighlight
    readonly property color foreground: Colors.fg
    readonly property color secondary: Colors.fgDark
    readonly property color separator: Colors.muted
    readonly property color blue: Colors.blue
    readonly property color magenta: Colors.magenta

    x: screen.virtualX + gap
    y: screen.virtualY + 8
    width: screen.width - 2 * gap
    height: 40
    title: "ATG"
    // wmd77 tiles dock windows. Its configured reserve_top provides the space.
    flags: Qt.X11BypassWindowManagerHint | Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus
    visible: true
    color: "transparent"

    // The reserved strip keeps tiled windows clear. Fullscreen clients can cover it.
    Component.onCompleted: Qt.callLater(() => bar.lower())

    component Label: Text {
        textFormat: Text.PlainText
        color: bar.foreground
        font.family: bar.iconFont
        font.pixelSize: 13
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
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
                        readonly property string label: bar.workspaces.names[index] || String(index + 1)

                        width: Math.max(26, Math.min(workspaceText.implicitWidth + 12, 100))
                        height: 26
                        radius: 6
                        color: selected ? bar.blue : workspaceHover.hovered ? bar.separator : bar.highlight

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
                            color: workspace.selected ? bar.background : bar.secondary
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
            anchors.left: centerRow.right
            anchors.leftMargin: bar.gap
            anchors.right: sessionDivider.left
            anchors.rightMargin: bar.gap
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            clip: true

            Row {
                anchors.right: parent.right
                height: parent.height
                spacing: bar.compact ? 12 : 26

                Label {
                    visible: bar.width >= 700 && bar.status.cpu >= 0
                    text: "󰻠 " + bar.status.cpu + "%"
                }

                Label {
                    visible: bar.width >= 700 && bar.status.memory >= 0
                    text: "󰍛 " + bar.status.memory + "%"
                }

                Label {
                    visible: bar.status.volume >= 0
                    text: (bar.status.muted ? "󰝟 " : "󰕾 ") + bar.status.volume + "%"
                    color: volumeHover.hovered ? bar.magenta : bar.foreground

                    Accessible.role: Accessible.Button
                    Accessible.name: "Show volume"
                    Accessible.onPressAction: bar.volumeRequested()

                    HoverHandler { id: volumeHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: bar.volumeRequested() }
                }

                Label {
                    visible: bar.width >= 400
                    width: Math.min(implicitWidth, 200)
                    elide: Text.ElideRight
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

                Label {
                    visible: bar.status.hasBattery
                    text: (bar.status.charging ? "󰂄 " : "󰁹 ") + bar.status.battery + "%"
                    color: bar.status.charging ? Colors.green : bar.status.battery < 20 ? Colors.red : bar.foreground
                }
            }
        }
    }

    Window {
        id: weatherTip

        screen: bar.screen
        x: Math.max(screen.virtualX + bar.gap, Math.min(
            bar.x + centerRow.x + weatherLabel.x + Math.round((weatherLabel.width - width) / 2),
            screen.virtualX + screen.width - width - bar.gap))
        y: bar.y + bar.height + bar.gap
        width: Math.min(tipLabel.implicitWidth + 24, screen.width - 2 * bar.gap)
        height: tipLabel.implicitHeight + 16
        flags: Qt.ToolTip | Qt.X11BypassWindowManagerHint | Qt.WindowDoesNotAcceptFocus |
            Qt.WindowTransparentForInput
        visible: weatherHover.hovered && !bar.launcherOpen && !bar.sessionOpen
        title: "ATG Weather"
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
                text: bar.weather.details
            }
        }
    }
}
