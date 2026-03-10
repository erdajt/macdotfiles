#!/usr/bin/env bash
set -euo pipefail

# macOS wallpaper picker - adapted from hyprland wallpicker.sh
# Uses osascript for selection dialog and desktoppr for wallpaper setting

STATE_FILE="$HOME/.config/aerospace/.theme-state"
WALL_STATE="$HOME/.config/aerospace/.wallpaper-state"
THEME="$(cat "$STATE_FILE" 2>/dev/null || echo tokyo-night)"

declare -A WALL_DIRS=(
    [everforest]="$HOME/Wallpapers/everforest"
    [tokyo-night]="$HOME/Wallpapers/tokyonight"
    [tokyo-dracula]="$HOME/Wallpapers/tokyonight"
    [dracula]="$HOME/Wallpapers/dracula"
    [nord]="$HOME/Wallpapers/nord"
    [catppuccin-mocha]="$HOME/Wallpapers/catppuccin"
    [rose-pine]="$HOME/Wallpapers/rose-pine"
)

WALLPAPER_DIR="${WALL_DIRS[$THEME]:-$HOME/Wallpapers}"
[[ -d "$WALLPAPER_DIR" ]] || WALLPAPER_DIR="$HOME/Wallpapers"

read_wall_state() {
    [[ -f "$WALL_STATE" ]] || return 1
    awk -F= -v t="$THEME" '$1==t{print $2}' "$WALL_STATE"
}

write_wall_state() {
    local path="$1" tmp
    tmp="$(mktemp)"
    touch "$WALL_STATE"
    awk -F= -v t="$THEME" -v p="$path" 'BEGIN{found=0} $1==t{print t"="p; found=1; next} {print $0} END{if(!found)print t"="p}' "$WALL_STATE" > "$tmp"
    mv "$tmp" "$WALL_STATE"
}

set_wallpaper() {
    local wp="$1"
    osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$wp\""
}

# Collect wallpapers
FILES=()
if [[ -d "$WALLPAPER_DIR" ]]; then
    while IFS= read -r -d '' f; do
        FILES+=("$f")
    done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) -print0 | sort -z)
fi

if [[ ${#FILES[@]} -eq 0 && -d "$HOME/Wallpapers" ]]; then
    while IFS= read -r -d '' f; do
        FILES+=("$f")
    done < <(find "$HOME/Wallpapers" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) -print0 | sort -z)
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
    osascript -e 'display notification "No wallpapers found in ~/Wallpapers" with title "Wallpaper Picker"'
    exit 1
fi

# Build menu list
names=()
for f in "${FILES[@]}"; do
    names+=("$(basename "$f")")
done

# Add random option
menu_items="Random Wallpaper"
for n in "${names[@]}"; do
    menu_items="$menu_items, $n"
done

# Show selection dialog
choice=$(osascript -e "choose from list {$(printf '"%s",' "Random Wallpaper" "${names[@]}" | sed 's/,$//') } with prompt \"Pick a wallpaper ($THEME)\" with title \"Wallpaper Picker\"" 2>/dev/null || echo "false")

[[ "$choice" == "false" ]] && exit 0

if [[ "$choice" == "Random Wallpaper" ]]; then
    selected="${FILES[RANDOM % ${#FILES[@]}]}"
else
    for f in "${FILES[@]}"; do
        if [[ "$(basename "$f")" == "$choice" ]]; then
            selected="$f"
            break
        fi
    done
fi

if [[ -n "${selected:-}" && -f "$selected" ]]; then
    set_wallpaper "$selected"
    write_wall_state "$selected"
    osascript -e "display notification \"$(basename "$selected")\" with title \"Wallpaper Set\""
fi
