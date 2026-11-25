#!/bin/sh
set -eu
export LC_ALL=C

sink=@DEFAULT_SINK@
case "$1" in
    volume-up) pactl set-sink-volume "$sink" +5% ;;
    volume-down) pactl set-sink-volume "$sink" -5% ;;
    volume-mute) pactl set-sink-mute "$sink" toggle ;;
    brightness-up) brightnessctl -c backlight -q set 5%+ ;;
    brightness-down) brightnessctl -c backlight -q set 5%- ;;
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
