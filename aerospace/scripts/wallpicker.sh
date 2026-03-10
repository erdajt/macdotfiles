#!/bin/zsh
PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$PATH"

STATE_FILE="$HOME/.config/aerospace/.theme-state"
WALL_STATE="$HOME/.config/aerospace/.wallpaper-state"
THEME="$(cat "$STATE_FILE" 2>/dev/null || echo tokyo-night)"

typeset -A WALL_DIRS
WALL_DIRS=(
    everforest "$HOME/Wallpapers/everforest"
    tokyo-night "$HOME/Wallpapers/tokyonight"
    tokyo-dracula "$HOME/Wallpapers/tokyonight"
    dracula "$HOME/Wallpapers/dracula"
    nord "$HOME/Wallpapers/nord"
    catppuccin-mocha "$HOME/Wallpapers/catppuccin"
    rose-pine "$HOME/Wallpapers/rose-pine"
)

WALLPAPER_DIR="${WALL_DIRS[$THEME]:-$HOME/Wallpapers}"
[[ -d "$WALLPAPER_DIR" ]] || WALLPAPER_DIR="$HOME/Wallpapers"

write_wall_state() {
    local path="$1" tmp
    tmp="$(/usr/bin/mktemp)"
    /usr/bin/touch "$WALL_STATE"
    /usr/bin/awk -F= -v t="$THEME" -v p="$path" 'BEGIN{found=0} $1==t{print t"="p; found=1; next} {print $0} END{if(!found)print t"="p}' "$WALL_STATE" > "$tmp"
    /bin/mv "$tmp" "$WALL_STATE"
}

# Collect wallpapers
FILES=( ${(f)"$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' \) 2>/dev/null | sort)"} )

if [[ ${#FILES[@]} -eq 0 && -d "$HOME/Wallpapers" ]]; then
    FILES=( ${(f)"$(find "$HOME/Wallpapers" -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' \) 2>/dev/null | sort)"} )
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
    osascript -e 'display notification "No wallpapers found" with title "Wallpaper Picker"'
    exit 1
fi

names=()
for f in "${FILES[@]}"; do
    names+=("$(basename "$f")")
done

choice=$(osascript -e "choose from list {$(printf '"%s",' "Random Wallpaper" "${names[@]}" | sed 's/,$//') } with prompt \"Pick a wallpaper ($THEME)\" with title \"Wallpaper Picker\"" 2>/dev/null || echo "false")

[[ "$choice" == "false" ]] && exit 0

if [[ "$choice" == "Random Wallpaper" ]]; then
    selected="${FILES[RANDOM % ${#FILES[@]} + 1]}"
else
    for f in "${FILES[@]}"; do
        if [[ "$(basename "$f")" == "$choice" ]]; then
            selected="$f"
            break
        fi
    done
fi

if [[ -n "${selected:-}" && -f "$selected" ]]; then
    osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$selected\""
    write_wall_state "$selected"
    osascript -e "display notification \"$(basename "$selected")\" with title \"Wallpaper Set\""
fi
