#!/bin/sh
set -eu
export LC_ALL=C

sink=@DEFAULT_SINK@
case "$1" in
    volume-up) pactl set-sink-volume "$sink" +5% ;;
    volume-down) pactl set-sink-volume "$sink" -5% ;;
    volume-mute) pactl set-sink-mute "$sink" toggle ;;
    volume-adjust) pactl set-sink-volume "$sink" "$2" ;;
    brightness-up) brightnessctl -c backlight -q set 5%+ ;;
    brightness-down) brightnessctl -c backlight -q set 5%- ;;
    power-cycle)
        current=$(powerprofilesctl get)
        available=$(powerprofilesctl list)
        next=
        seen_current=false
        first=
        for profile in performance balanced power-saver; do
            if ! printf '%s\n' "$available" | grep -Eq "^[[:space:]*]*$profile:"; then
                continue
            fi
            if [ -z "$first" ]; then
                first=$profile
            fi
            if "$seen_current"; then
                next=$profile
                break
            fi
            if [ "$profile" = "$current" ]; then
                seen_current=true
            fi
        done
        next=${next:-$first}
        if [ -n "$next" ] && [ "$next" != "$current" ]; then
            powerprofilesctl set "$next"
        fi
        printf 'power %s\n' "$(powerprofilesctl get)"
        exit
        ;;
    power-profile)
        if profile=$(powerprofilesctl get 2>/dev/null); then
            printf 'power-profile %s\n' "$profile"
        fi
        exit
        ;;
    volume|brightness) ;;
    *) exit 2 ;;
esac

case "$1" in
    volume*)
        volume=$(pactl get-sink-volume "$sink")
        mute=$(pactl get-sink-mute "$sink")
        level=$(printf '%s\n' "$volume" | awk 'match($0, /[0-9]+%/) { print substr($0, RSTART, RLENGTH - 1); exit }')
        [ -n "$level" ] && printf 'volume %s %s\n' "$level" "${mute#Mute: }"
        ;;
    brightness*)
        brightness=$(brightnessctl -c backlight -m)
        level=$(printf '%s\n' "$brightness" | awk -F, 'NR == 1 { sub(/%$/, "", $4); print $4 }')
        [ -n "$level" ] && printf 'brightness %s no\n' "$level"
        ;;
esac
