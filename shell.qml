//@ pragma Env QS_NO_RELOAD_POPUP = 1
import QtQuick
import Quickshell
import "theme"

ShellRoot {
    id: root

    readonly property var systemLocale: Qt.locale()

    Launcher { id: appLauncher }
    SessionMenu { id: sessionMenu }
    Osd { id: osdPopup }
    EwmhWorkspaces { id: desktopWorkspaces }
    BarStatus { id: desktopStatus }
    Weather { id: localWeather }
    WallpaperState { id: wallpaperState }
    WallpaperPicker { wallpaper: wallpaperState }

    Binding {
        target: Colors
        property: "wallpaperPath"
        value: wallpaperState.currentPath
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Variants {
        model: Qt.application.screens

        Bar {
            required property var modelData

            screen: modelData
            workspaces: desktopWorkspaces
            status: desktopStatus
            weather: localWeather
            clockText: clock.date.toLocaleDateString(root.systemLocale, "ddd d MMM")
                + "  " + clock.date.toLocaleTimeString(root.systemLocale, Locale.ShortFormat)
            launcherOpen: appLauncher.visible && appLauncher.screen === screen
            sessionOpen: sessionMenu.visible && sessionMenu.screen === screen
            osdOpen: osdPopup.visible && osdPopup.screen === screen
            profileLabel: osdPopup.profileLabel
            onLauncherRequested: appLauncher.toggle(screen)
            onSessionRequested: sessionMenu.toggle(screen)
            onVolumeRequested: osdPopup.enqueue("volume")
            onNetworkRequested: appLauncher.runInTerminal(["nmtui"], "")
            onProfileRequested: osdPopup.enqueue("power-profile")
            onProfileCycleRequested: osdPopup.enqueue("power-cycle")
            onMonitorRequested: mode => Quickshell.execDetached([
                "env", "GDK_BACKEND=x11", "flock", "-o",
                Quickshell.env("XDG_RUNTIME_DIR") + "/atg-monitor.lock",
                Quickshell.shellPath("monitor/d77-monitor"), mode
            ])
        }
    }
}
