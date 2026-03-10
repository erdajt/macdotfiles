#!/bin/zsh
PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$PATH"
SCRIPT_PATH="${0:A}"

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

# Theme-aware fzf colors
typeset -A FZF_COLORS
FZF_COLORS=(
    tokyo-night "--color=bg+:#24283b,bg:#1a1b26,fg:#c0caf5,fg+:#c0caf5,hl:#7aa2f7,hl+:#7dcfff,prompt:#7aa2f7,pointer:#f7768e,marker:#9ece6a,border:#7aa2f7"
    everforest "--color=bg+:#2e383c,bg:#272e33,fg:#d3c6aa,fg+:#d3c6aa,hl:#a7c080,hl+:#83c092,prompt:#a7c080,pointer:#e67e80,marker:#a7c080,border:#a7c080"
    dracula "--color=bg+:#44475a,bg:#282a36,fg:#f8f8f2,fg+:#f8f8f2,hl:#bd93f9,hl+:#ff79c6,prompt:#bd93f9,pointer:#ff5555,marker:#50fa7b,border:#bd93f9"
    tokyo-dracula "--color=bg+:#44475a,bg:#282a36,fg:#f8f8f2,fg+:#f8f8f2,hl:#bd93f9,hl+:#ff79c6,prompt:#bd93f9,pointer:#ff5555,marker:#50fa7b,border:#bd93f9"
    nord "--color=bg+:#3b4252,bg:#2e3440,fg:#eceff4,fg+:#eceff4,hl:#88c0d0,hl+:#8fbcbb,prompt:#88c0d0,pointer:#bf616a,marker:#a3be8c,border:#88c0d0"
    catppuccin-mocha "--color=bg+:#313244,bg:#1e1e2e,fg:#cdd6f4,fg+:#cdd6f4,hl:#89b4fa,hl+:#74c7ec,prompt:#89b4fa,pointer:#f38ba8,marker:#a6e3a1,border:#89b4fa"
    rose-pine "--color=bg+:#26233a,bg:#191724,fg:#e0def4,fg+:#e0def4,hl:#c4a7e7,hl+:#9ccfd8,prompt:#c4a7e7,pointer:#eb6f92,marker:#31748f,border:#c4a7e7"
)

theme_label() {
    case "$1" in
        everforest) echo " Everforest" ;;
        tokyo-night) echo " Tokyo Night" ;;
        tokyo-dracula) echo " Tokyo/Dracula" ;;
        dracula) echo " Dracula" ;;
        nord) echo " Nord" ;;
        catppuccin-mocha) echo " Catppuccin Mocha" ;;
        rose-pine) echo " Rose Pine" ;;
        *) echo "$1" ;;
    esac
}

read_wall_state() {
    local theme="$1"
    [[ -f "$WALL_STATE" ]] || return 1
    /usr/bin/awk -F= -v t="$theme" '$1==t{print $2}' "$WALL_STATE"
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
    local files=( ${(f)"$(/usr/bin/find "$dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' \) 2>/dev/null)"} )
    [[ ${#files[@]} -gt 0 ]] || return 1
    echo "${files[RANDOM % ${#files[@]} + 1]}"
}

apply_theme() {
    local theme="$1"

    # Alacritty
    local alac="${ALACRITTY_THEME[$theme]}"
    if [[ -n "$alac" && -f "$alac" ]]; then
        /bin/cp "$alac" "$ALACRITTY_ACTIVE"
        alacritty msg config-reload >/dev/null 2>&1 || true
    fi

    # Borders
    local ac="${BORDER_ACTIVE[$theme]:-0xff7aa2f7}"
    local ic="${BORDER_INACTIVE[$theme]:-0xff24283b}"
    /usr/bin/pkill -x borders 2>/dev/null || true
    borders active_color="$ac" inactive_color="$ic" width=3.0 style=round &

    # Save state BEFORE reloading sketchybar so colors.lua reads new theme
    echo "$theme" > "$STATE_FILE"
    echo "$theme" > "$NVIM_THEME_FILE" 2>/dev/null || true

    # Sketchybar - reload to pick up new theme colors
    sketchybar --reload 2>/dev/null || true

    # Wallpaper
    local wp
    wp="$(read_wall_state "$theme" 2>/dev/null || true)"
    if [[ -z "${wp:-}" || ! -f "$wp" ]]; then
        wp="$(pick_wallpaper "$theme" 2>/dev/null || true)"
    fi
    if [[ -n "${wp:-}" && -f "$wp" ]]; then
        /usr/bin/osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$wp\"" 2>/dev/null || true
        write_wall_state "$theme" "$wp"
    fi

    /usr/bin/osascript -e "display notification \"$(theme_label "$theme")\" with title \"Theme Switched\"" 2>/dev/null || true
}

# fzf picker mode - runs inside floating alacritty
run_picker() {
    local current="$1"
    local fzf_theme="${FZF_COLORS[$current]:-${FZF_COLORS[tokyo-night]}}"

    local labels=()
    for t in "${THEMES[@]}"; do
        if [[ "$t" == "$current" ]]; then
            labels+=("$(theme_label "$t") [active]")
        else
            labels+=("$(theme_label "$t")")
        fi
    done

    local choice
    choice=$(printf '%s\n' "${labels[@]}" | fzf ${=fzf_theme} --border=rounded --prompt="theme > " --header="  Select Theme" --reverse --height=100%)

    [[ -z "$choice" ]] && exit 0

    # Strip [active] and icons, map back to theme key
    choice="${choice% \[active\]}"
    choice="${choice## }"
    for t in "${THEMES[@]}"; do
        if [[ "$(theme_label "$t")" == " $choice" || "$(theme_label "$t")" == "$choice" ]]; then
            echo "$t" > /tmp/theme-toggle-result
            return 0
        fi
    done
    return 1
}

main() {
    local current next no_menu=false
    current="$(/bin/cat "$STATE_FILE" 2>/dev/null || echo "tokyo-night")"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --apply-current) no_menu=true ;;
            --theme) shift; next="$1" ;;
            --no-menu) no_menu=true ;;
            --pick)
                run_picker "$current"
                exit $?
                ;;
        esac
        shift
    done

    if [[ -z "${next:-}" ]]; then
        if $no_menu; then
            next="$current"
        else
            # Launch fzf in floating alacritty
            /bin/rm -f /tmp/theme-toggle-result
            # Launch fzf in centered floating alacritty
            # Screen: 1280x832, picker ~500x300 -> pos ~390,266
            alacritty --title "Theme Toggle" \
                -o 'window.dimensions.columns=40' \
                -o 'window.dimensions.lines=12' \
                -o 'window.decorations="none"' \
                -o 'window.position.x=390' \
                -o 'window.position.y=266' \
                -o 'window.startup_mode="Windowed"' \
                -e "$SCRIPT_PATH" --pick
            # Read result
            [[ -f /tmp/theme-toggle-result ]] || exit 0
            next="$(/bin/cat /tmp/theme-toggle-result)"
            /bin/rm -f /tmp/theme-toggle-result
            [[ -n "$next" ]] || exit 0
        fi
    fi

    apply_theme "$next"
}

main "$@"
