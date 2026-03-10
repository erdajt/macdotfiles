#!/bin/zsh
PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$PATH"

THEMES=(everforest tokyo-night tokyo-dracula dracula nord catppuccin-mocha rose-pine)
STATE_FILE="$HOME/.config/aerospace/.theme-state"
NVIM_THEME_FILE="$HOME/.config/nvim/.theme"
WALL_STATE="$HOME/.config/aerospace/.wallpaper-state"
ALACRITTY_ACTIVE="$HOME/.config/alacritty/themes/active.toml"

typeset -A BORDER_ACTIVE
BORDER_ACTIVE=(
    everforest "0xffa7c080" tokyo-night "0xff7aa2f7" tokyo-dracula "0xffbd93f9"
    dracula "0xffbd93f9" nord "0xff88c0d0" catppuccin-mocha "0xff89b4fa" rose-pine "0xffc4a7e7"
)

typeset -A BORDER_INACTIVE
BORDER_INACTIVE=(
    everforest "0xff2b3339" tokyo-night "0xff24283b" tokyo-dracula "0xff282a36"
    dracula "0xff282a36" nord "0xff3b4252" catppuccin-mocha "0xff313244" rose-pine "0xff26233a"
)

typeset -A ALACRITTY_THEME
ALACRITTY_THEME=(
    everforest "$HOME/.config/alacritty/themes/everforest.toml"
    tokyo-night "$HOME/.config/alacritty/themes/tokyo-night.toml"
    tokyo-dracula "$HOME/.config/alacritty/themes/tokyo-dracula.toml"
    dracula "$HOME/.config/alacritty/themes/dracula.toml"
    nord "$HOME/.config/alacritty/themes/nord.toml"
    catppuccin-mocha "$HOME/.config/alacritty/themes/catppuccin-mocha.toml"
    rose-pine "$HOME/.config/alacritty/themes/rose-pine.toml"
)

typeset -A WALL_DIRS
WALL_DIRS=(
    everforest "$HOME/Wallpapers/everforest" tokyo-night "$HOME/Wallpapers/tokyonight"
    tokyo-dracula "$HOME/Wallpapers/tokyonight" dracula "$HOME/Wallpapers/dracula"
    nord "$HOME/Wallpapers/nord" catppuccin-mocha "$HOME/Wallpapers/catppuccin"
    rose-pine "$HOME/Wallpapers/rose-pine"
)

theme_label() {
    case "$1" in
        everforest) echo "Everforest" ;;
        tokyo-night) echo "Tokyo Night" ;;
        tokyo-dracula) echo "Tokyo/Dracula Mix" ;;
        dracula) echo "Dracula" ;;
        nord) echo "Nord" ;;
        catppuccin-mocha) echo "Catppuccin Mocha" ;;
        rose-pine) echo "Rose Pine" ;;
        *) echo "$1" ;;
    esac
}

read_wall_state() {
    local theme="$1"
    [[ -f "$WALL_STATE" ]] || return 1
    awk -F= -v t="$theme" '$1==t{print $2}' "$WALL_STATE"
}

write_wall_state() {
    local theme="$1" path="$2" tmp
    tmp="$(/usr/bin/mktemp)"
    /usr/bin/touch "$WALL_STATE"
    /usr/bin/awk -F= -v t="$theme" -v p="$path" 'BEGIN{found=0} $1==t{print t"="p; found=1; next} {print $0} END{if(!found)print t"="p}' "$WALL_STATE" > "$tmp"
    /bin/mv "$tmp" "$WALL_STATE"
}

pick_wallpaper() {
    local theme="$1"
    local dir="${WALL_DIRS[$theme]:-$HOME/Wallpapers}"
    [[ -d "$dir" ]] || dir="$HOME/Wallpapers"
    [[ -d "$dir" ]] || return 1

    local files=( ${(f)"$(find "$dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' \) 2>/dev/null)"} )
    [[ ${#files[@]} -gt 0 ]] || return 1
    echo "${files[RANDOM % ${#files[@]} + 1]}"
}

apply_theme() {
    local theme="$1"

    # Alacritty
    local alac="${ALACRITTY_THEME[$theme]}"
    if [[ -n "$alac" && -f "$alac" ]]; then
        cp "$alac" "$ALACRITTY_ACTIVE"
        alacritty msg config-reload >/dev/null 2>&1 || true
    fi

    # Borders
    local ac="${BORDER_ACTIVE[$theme]:-0xff7aa2f7}"
    local ic="${BORDER_INACTIVE[$theme]:-0xff24283b}"
    pkill -x borders 2>/dev/null || true
    borders active_color="$ac" inactive_color="$ic" width=3.0 style=round &

    # Save state
    echo "$theme" > "$STATE_FILE"
    echo "$theme" > "$NVIM_THEME_FILE" 2>/dev/null || true

    # Sketchybar - reload to pick up new theme
    sketchybar --reload 2>/dev/null || true

    # Wallpaper
    local wp
    wp="$(read_wall_state "$theme" 2>/dev/null || true)"
    if [[ -z "${wp:-}" || ! -f "$wp" ]]; then
        wp="$(pick_wallpaper "$theme" 2>/dev/null || true)"
    fi
    if [[ -n "${wp:-}" && -f "$wp" ]]; then
        osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$wp\"" 2>/dev/null || true
        write_wall_state "$theme" "$wp"
    fi

    osascript -e "display notification \"$(theme_label "$theme")\" with title \"Theme Switched\"" 2>/dev/null || true
}

choose_theme() {
    local current="$1"
    local labels=()
    for t in "${THEMES[@]}"; do
        if [[ "$t" == "$current" ]]; then
            labels+=("$(theme_label "$t") [active]")
        else
            labels+=("$(theme_label "$t")")
        fi
    done

    local choice
    choice=$(osascript -e "choose from list {$(printf '"%s",' "${labels[@]}" | sed 's/,$//') } with prompt \"Select Theme\" with title \"Theme Toggle\" default items {\"$(theme_label "$current") [active]\"}" 2>/dev/null || echo "false")

    [[ "$choice" == "false" ]] && return 1

    choice="${choice% \[active\]}"
    for t in "${THEMES[@]}"; do
        if [[ "$(theme_label "$t")" == "$choice" ]]; then
            echo "$t"
            return 0
        fi
    done
    return 1
}

main() {
    local current next no_menu=false
    current="$(cat "$STATE_FILE" 2>/dev/null || echo "tokyo-night")"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --apply-current) no_menu=true ;;
            --theme) shift; next="$1" ;;
            --no-menu) no_menu=true ;;
        esac
        shift
    done

    if [[ -z "${next:-}" ]]; then
        if $no_menu; then
            next="$current"
        else
            next="$(choose_theme "$current")" || exit 0
        fi
    fi

    apply_theme "$next"
}

main "$@"
