<p align="center">
  <img src="assets/ATG.png" width="128" alt="ATG logo">
</p>

<h1 align="center">ATG · At the Gates</h1>

<p align="center">
  A lightweight X11 desktop shell with a top bar, application launcher, wallpaper picker,
  session menu, and volume and brightness indicators.
</p>

## What is this?

ATG adapts [Utumno](https://github.com/dani-77/utumno) to Xorg with
[Quickshell](https://quickshell.org). Its first supported window manager is
[wmd77](https://github.com/d77void/wmd77). The bar reads and changes workspaces through
EWMH. The session menu uses [Amorphis](https://github.com/dani-77/amorphis) to lock the screen.

## Before you install

- Quickshell with X11 support, wmd77, and an Xorg session.
- A C compiler, `make`, and the Xlib development headers to build the workspace helper.
- `feh`, `jq`, Bash, and `flock` for wallpaper selection. The decorative backdrop uses Python 3,
  `xrandr`, and ImageMagick. Install [Matugen](https://github.com/InioX/matugen) 4.x for wallpaper colors.
- `pactl` for volume, `brightnessctl` for backlight control, and Amorphis and `loginctl`
  for the session actions. Network and battery status use NetworkManager and UPower.

## Installing

Clone ATG into Quickshell's config directory and build the workspace helper.

```sh
qs_config="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
mkdir -p "$qs_config"
git clone https://github.com/d77void/ATG.git "$qs_config/atg"
make -C "$qs_config/atg"
```

In your wmd77 config, disable the built-in bar and reserve 48 pixels for ATG.

```toml
[bar]
enable = false
reserve_top = 48
```

Add the following line to the startup script configured under `[apps].startup_script`.
Let ATG manage the background in that session by removing any other wallpaper command
from the startup script.

```sh
QT_QPA_PLATFORM=xcb qs -n -d -c atg
```

You can also run that command from an Xorg terminal. The `-n` option keeps one
instance when wmd77 reloads the startup script.

## Using it

The left side of the bar contains the launcher and clickable workspaces. Weather and
the clock sit in the center. CPU, memory, volume, network, battery and the session button
are on the right. The date and time use the system locale. The weather display queries
[wttr.in](https://github.com/chubin/wttr.in) with `curl`. Set `ATG_WEATHER_LOCATION` in the
session environment to specify a location.

Suggested wmd77 bindings

| Shortcut | Action |
| --- | --- |
| `Super+D` | Open or close the launcher |
| `Super+Y` | Open or close the wallpaper picker |
| Volume and brightness keys | Change the level and show the OSD |

To add a binding, include a block like this in your wmd77 config. Reload wmd77 to apply it.

```toml
[[bind]]
key = "M-y"
action = "spawn"
arg = "qs -c atg ipc call wallpaper toggle"
```

Use the same form for `M-d` with `launcher toggle`. For the media keys, call the `osd`
target with `volumeUp`, `volumeDown`, `volumeMuteToggle`, `brightnessUp` or `brightnessDown`.
With [qsd77](https://github.com/dani-77/qsd77), the popup commands are shorter.

```sh
qsd77 launcher -c atg
qsd77 wallpaper -c atg
qsd77 session -c atg
```

### Changing your wallpaper

The picker displays images from `~/Wallpaper`. Set `ATG_WALLPAPER_DIR` to use another
directory. ATG remembers the chosen image and restores it on startup.

**Clear** brings back the Utumno-style backdrop and the base Tokyo Night colors. The
backdrop is also the default on a fresh install. **Theme mix** adjusts how much of the
Matugen palette ATG uses. The palette and mix setting are shared with Utumno and other
d77 shells.

## Uninstalling

Stop ATG with `qs -c atg kill`. Remove the ATG entry from your wmd77 startup script
and undo the bar and shortcut settings you added. You can then remove the ATG clone
from the Quickshell config directory.

## More

The desktop background is applied as an X11 root pixmap. To inspect the available
IPC actions, run `qs -c atg ipc show`.

## License

MIT. See [LICENSE](LICENSE).
