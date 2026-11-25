#!/usr/bin/env bash
set -euo pipefail

state_dir=${XDG_STATE_HOME:-"$HOME/.local/state"}/atg
palette_dir=${XDG_CACHE_HOME:-"$HOME/.cache"}/d77
config_dir=${XDG_CONFIG_HOME:-"$HOME/.config"}/d77
state_file=$state_dir/wallpaper
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
state_tmp=
work_dir=
mix_tmp=

cleanup() {
    [[ -z $state_tmp ]] || rm -f -- "$state_tmp"
    [[ -z $work_dir ]] || rm -rf -- "$work_dir"
    [[ -z $mix_tmp ]] || rm -f -- "$mix_tmp"
}
trap cleanup EXIT

if [[ ${1:-} == mix ]]; then
    mkdir -p -- "$config_dir"
    mix_tmp=$(mktemp -- "$config_dir/.theme-mix.XXXXXX")
    jq -en --arg mix "${2:-}" '$mix | tonumber | select(. >= 0 and . <= 1)' >"$mix_tmp"
    mv -f -- "$mix_tmp" "$config_dir/theme-mix"
    exit
fi

mkdir -p -- "$state_dir"
exec 9>"$state_dir/wallpaper.lock"
flock 9

report() {
    jq -cn --arg path "$1" '{path: $path}'
}

case ${1:-} in
    apply)
        path=$(realpath -e -- "${2:?Missing image path}")
        ;;
    clear)
        path=
        ;;
    restore)
        path=
        if [[ -f $state_file ]]; then
            path=$(cat -- "$state_file")
            if [[ -n $path && ! -f $path ]]; then
                echo "Saved wallpaper is unavailable: $path" >&2
                path=
            fi
        fi
        ;;
    *)
        echo "Usage: $0 {apply PATH|clear|restore|mix VALUE}" >&2
        exit 2
        ;;
esac

if [[ $1 != restore ]]; then
    state_tmp=$(mktemp -- "$state_dir/.wallpaper.XXXXXX")
    printf '%s\n' "$path" >"$state_tmp"
fi

if [[ -z $path ]]; then
    work_dir=$(mktemp -d -- "$state_dir/.backdrop.XXXXXX")
    if ! {
        LC_ALL=C python3 "$script_dir/backdrop/render.py" "$work_dir/backdrop.svg" &&
        magick "$work_dir/backdrop.svg" -alpha off "$work_dir/backdrop.png" &&
        feh --no-fehbg --no-xinerama --bg-center -- "$work_dir/backdrop.png"
    }; then
        echo "Could not render the backdrop. Using a solid background." >&2
        printf 'P3\n1 1\n255\n26 27 38\n' >"$work_dir/background.ppm"
        feh --no-fehbg --bg-tile -- "$work_dir/background.ppm"
    fi
elif [[ -f $path ]]; then
    feh --no-fehbg --bg-fill -- "$path"
else
    echo "Wallpaper is unavailable: $path" >&2
    exit 1
fi

if [[ -n $state_tmp ]]; then
    mv -f -- "$state_tmp" "$state_file"
fi
report "$path"

generate_palette() {
    mkdir -p -- "$palette_dir" || return
    work_dir=$(mktemp -d -- "$palette_dir/.atg-palette.XXXXXX") || return
    cp -- "$script_dir/theme/matugen.toml" "$script_dir/theme/d77-palette.json" "$work_dir/" || return
    (cd -- "$work_dir" && matugen -c matugen.toml image "$path" \
        --source-color-index 0 -t scheme-vibrant -m dark -q) </dev/null >&2 || return
    jq -e --arg source "$path" '.source = $source' "$work_dir/palette.json" >"$work_dir/ready.json" || return
    mv -f -- "$work_dir/ready.json" "$palette_dir/palette.json"
}

if [[ -n $path ]] && ! generate_palette; then
    echo "Wallpaper applied, but Matugen could not generate its palette." >&2
fi
