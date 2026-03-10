#!/bin/zsh
PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$PATH"
SCRIPT_PATH="${0:A}"

STATE_FILE="$HOME/.config/aerospace/.theme-state"
THEME="$(/bin/cat "$STATE_FILE" 2>/dev/null || echo tokyo-night)"

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

if [[ "$1" == "--pick" ]]; then
    local fzf_theme="${FZF_COLORS[$THEME]:-${FZF_COLORS[tokyo-night]}}"

    # Collect .app names from /Applications and ~/Applications
    local apps=()
    for dir in /Applications /Applications/Utilities ~/Applications /System/Applications; do
        [[ -d "$dir" ]] || continue
        for app in "$dir"/*.app(N); do
            apps+=("${app:t:r}")
        done
    done

    # Sort and deduplicate
    local choice
    choice=$(printf '%s\n' "${(u)apps[@]}" | /usr/bin/sort | fzf ${=fzf_theme} --border=rounded --prompt="launch > " --header="  Apps" --reverse --height=100%)

    [[ -z "$choice" ]] && exit 0
    echo "$choice" > /tmp/launcher-result
    exit 0
fi

local cols=45 lines=15
local pos_x=640 pos_y=0

# Launch picker in floating alacritty
/bin/rm -f /tmp/launcher-result
alacritty --title "App Launcher" \
    -o "window.dimensions.columns=$cols" \
    -o "window.dimensions.lines=$lines" \
    -o 'window.decorations="none"' \
    -o "window.position.x=$pos_x" \
    -o "window.position.y=$pos_y" \
    -o 'window.startup_mode="Windowed"' \
    -e "$SCRIPT_PATH" --pick

# Read result after alacritty closes
if [[ -f /tmp/launcher-result ]]; then
    local choice="$(/bin/cat /tmp/launcher-result)"
    /bin/rm -f /tmp/launcher-result
    [[ -n "$choice" ]] && open -a "$choice"
fi
