import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell.Io
import "theme"

Window {
    id: picker

    required property WallpaperState wallpaper
    property var targetScreen: Qt.application.screens[0]

    screen: targetScreen
    x: targetScreen.virtualX + Math.round((targetScreen.width - width) / 2)
    y: targetScreen.virtualY + Math.round((targetScreen.height - height) / 2)
    width: Math.min(720, targetScreen.width - 20)
    height: Math.min(520, targetScreen.height - 20)
    flags: Qt.Popup | Qt.X11BypassWindowManagerHint | Qt.FramelessWindowHint
    title: "ATG Wallpaper"
    color: "transparent"

    function open(): void {
        if (visible)
            return;
        show();
        requestActivate();
        grid.forceActiveFocus();
    }

    function applyRandom(): void {
        if (images.count)
            wallpaper.run("apply", images.get(Math.floor(Math.random() * images.count), "filePath"));
    }

    FolderListModel {
        id: images
        folder: "file://" + picker.wallpaper.directory.split("/").map(encodeURIComponent).join("/")
        showDirs: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"]
    }

    IpcHandler {
        target: "wallpaper"
        function open(): void { picker.open(); }
        function close(): void { picker.hide(); }
        function toggle(): void { if (picker.visible) picker.hide(); else picker.open(); }
        function reload(): void { picker.wallpaper.run("restore", ""); }
        function set(path: string): void { picker.wallpaper.run("apply", path); }
        function random(): void { picker.applyRandom(); }
        function clear(): void { picker.wallpaper.run("clear", ""); }
    }

    component ActionButton: Button {
        id: button
        implicitHeight: 32
        leftPadding: 12
        rightPadding: 12
        contentItem: Text {
            text: button.text
            color: button.enabled ? Colors.fg : Colors.fgDark
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 6
            color: button.hovered || button.activeFocus ? Colors.muted : Colors.bgHighlight
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Colors.bg
        border.color: Colors.magenta
        border.width: 2
        Keys.onEscapePressed: picker.hide()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "Wallpapers"
                    color: Colors.fg
                    font.pixelSize: 16
                    font.bold: true
                }

                ActionButton {
                    text: "Random"
                    enabled: images.count > 0
                    onClicked: picker.applyRandom()
                }

                ActionButton {
                    text: "Clear"
                    onClicked: picker.wallpaper.run("clear", "")
                }
            }

            GridView {
                id: grid

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: images
                cellWidth: width / Math.max(1, Math.floor(width / 155))
                cellHeight: 114
                keyNavigationEnabled: true
                boundsBehavior: Flickable.StopAtBounds

                function applyCurrent(): void {
                    if (currentIndex >= 0 && currentIndex < images.count)
                        picker.wallpaper.run("apply", images.get(currentIndex, "filePath"));
                }
                Keys.onEnterPressed: applyCurrent()
                Keys.onReturnPressed: applyCurrent()

                delegate: Item {
                    id: tile

                    required property int index
                    required property string filePath
                    required property url fileUrl
                    required property string fileName
                    readonly property bool applied: picker.wallpaper.currentPath === filePath

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 7
                        color: Colors.bgHighlight
                        border.color: tile.applied ? Colors.blue : tile.GridView.isCurrentItem ? Colors.magenta : Colors.muted
                        border.width: tile.applied || tile.GridView.isCurrentItem ? 2 : 1

                        Image {
                            anchors.fill: parent
                            anchors.margins: 3
                            anchors.bottomMargin: 24
                            source: tile.fileUrl
                            sourceSize.width: 240
                            sourceSize.height: 145
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            clip: true
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 6
                            text: tile.fileName
                            textFormat: Text.PlainText
                            elide: Text.ElideMiddle
                            horizontalAlignment: Text.AlignHCenter
                            color: Colors.fg
                            font.pixelSize: 12
                        }
                    }

                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            grid.currentIndex = tile.index;
                            grid.forceActiveFocus();
                            grid.applyCurrent();
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: images.count === 0
                    text: images.status === FolderListModel.Loading ? "Loading wallpapers…" : "No wallpapers found"
                    color: Colors.fgDark
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text { text: "Theme mix"; color: Colors.fg }

                Slider {
                    id: mixSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    stepSize: 0.01
                    value: Colors.mix
                    enabled: Colors.paletteValid
                    onMoved: Colors.setMix(value)

                    background: Rectangle {
                        x: mixSlider.leftPadding
                        y: mixSlider.topPadding + (mixSlider.availableHeight - height) / 2
                        width: mixSlider.availableWidth
                        height: 5
                        radius: 3
                        color: Colors.muted
                        Rectangle {
                            width: parent.width * mixSlider.visualPosition
                            height: parent.height
                            radius: parent.radius
                            color: Colors.magenta
                        }
                    }
                    handle: Rectangle {
                        x: mixSlider.leftPadding + mixSlider.visualPosition * (mixSlider.availableWidth - width)
                        y: mixSlider.topPadding + (mixSlider.availableHeight - height) / 2
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: 7
                        color: Colors.magenta
                        opacity: mixSlider.enabled ? 1 : 0.55
                    }
                }

                Text { text: Math.round(Colors.mix * 100) + "%"; color: Colors.fg }
            }

            Text {
                Layout.fillWidth: true
                text: picker.wallpaper.busy ? "Applying wallpaper…" : picker.wallpaper.message
                visible: text !== ""
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: picker.wallpaper.busy ? Colors.fgDark : Colors.red
            }
        }
    }
}
