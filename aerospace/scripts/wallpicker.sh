#!/bin/zsh
PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$PATH"
SCRIPT_PATH="${0:A}"

STATE_FILE="$HOME/.config/aerospace/.theme-state"
WALL_STATE="$HOME/.config/aerospace/.wallpaper-state"
RESULT_FILE="/tmp/wallpicker-result"
THEME="$(/bin/cat "$STATE_FILE" 2>/dev/null || echo tokyo-night)"

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

# Theme-aware fzf colors
typeset -A FZF_COLORS
FZF_COLORS=(
    tokyo-night "--color=bg+:#24283b,bg:#1a1b26,fg:#c0caf5,fg+:#c0caf5,hl:#7aa2f7,hl+:#7dcfff,info:#bb9af7,prompt:#7aa2f7,pointer:#f7768e,marker:#9ece6a,spinner:#bb9af7,header:#565f89,border:#7aa2f7"
    everforest "--color=bg+:#2e383c,bg:#272e33,fg:#d3c6aa,fg+:#d3c6aa,hl:#a7c080,hl+:#83c092,info:#d699b6,prompt:#a7c080,pointer:#e67e80,marker:#a7c080,spinner:#d699b6,header:#859289,border:#a7c080"
    dracula "--color=bg+:#44475a,bg:#282a36,fg:#f8f8f2,fg+:#f8f8f2,hl:#bd93f9,hl+:#ff79c6,info:#6272a4,prompt:#bd93f9,pointer:#ff5555,marker:#50fa7b,spinner:#bd93f9,header:#6272a4,border:#bd93f9"
    tokyo-dracula "--color=bg+:#44475a,bg:#282a36,fg:#f8f8f2,fg+:#f8f8f2,hl:#bd93f9,hl+:#ff79c6,info:#6272a4,prompt:#bd93f9,pointer:#ff5555,marker:#50fa7b,spinner:#bd93f9,header:#6272a4,border:#bd93f9"
    nord "--color=bg+:#3b4252,bg:#2e3440,fg:#eceff4,fg+:#eceff4,hl:#88c0d0,hl+:#8fbcbb,info:#b48ead,prompt:#88c0d0,pointer:#bf616a,marker:#a3be8c,spinner:#b48ead,header:#4c566a,border:#88c0d0"
    catppuccin-mocha "--color=bg+:#313244,bg:#1e1e2e,fg:#cdd6f4,fg+:#cdd6f4,hl:#89b4fa,hl+:#74c7ec,info:#cba6f7,prompt:#89b4fa,pointer:#f38ba8,marker:#a6e3a1,spinner:#cba6f7,header:#585b70,border:#89b4fa"
    rose-pine "--color=bg+:#26233a,bg:#191724,fg:#e0def4,fg+:#e0def4,hl:#c4a7e7,hl+:#9ccfd8,info:#c4a7e7,prompt:#c4a7e7,pointer:#eb6f92,marker:#31748f,spinner:#c4a7e7,header:#6e6a86,border:#c4a7e7"
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

# If running inside the fzf picker terminal
if [[ "$1" == "--pick" ]]; then
    local fzf_theme="${FZF_COLORS[$THEME]:-${FZF_COLORS[tokyo-night]}}"
    local files=( ${(f)"$(/usr/bin/find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' \) 2>/dev/null | /usr/bin/sort)"} )
    [[ ${#files[@]} -eq 0 ]] && exit 1

    local names=("🎲 Random")
    for f in "${files[@]}"; do names+=("$(/usr/bin/basename "$f")"); done

    choice=$(printf '%s\n' "${names[@]}" | fzf ${=fzf_theme} --border=rounded --prompt="wallpaper > " --header="  Theme: $THEME" --reverse --height=100%)

    [[ -z "$choice" ]] && exit 0

    if [[ "$choice" == "🎲 Random" ]]; then
        selected="${files[RANDOM % ${#files[@]} + 1]}"
    else
        for f in "${files[@]}"; do
            [[ "$(/usr/bin/basename "$f")" == "$choice" ]] && selected="$f" && break
        done
    fi

    if [[ -n "${selected:-}" && -f "$selected" ]]; then
        /usr/bin/osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$selected\"" 2>/dev/null
        write_wall_state "$selected"
    fi
    exit 0
fi

# Launch fzf picker in a centered floating alacritty window
# Screen: 1280x832, picker ~700x500 -> pos ~290,166
alacritty --title "Wallpaper Picker" \
    -o 'window.dimensions.columns=60' \
    -o 'window.dimensions.lines=20' \
    -o 'window.decorations="none"' \
    -o 'window.position.x=290' \
    -o 'window.position.y=166' \
    -o 'window.startup_mode="Windowed"' \
    -e "$SCRIPT_PATH" --pick &
