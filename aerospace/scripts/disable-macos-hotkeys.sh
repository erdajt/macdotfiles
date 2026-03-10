#!/usr/bin/env bash
# Disable macOS system shortcuts that conflict with aerospace keybinds
# Run once after setup, requires logout/login to take full effect

echo "Disabling conflicting macOS keyboard shortcuts..."

# Disable Spotlight (cmd+space) - we use it for app launcher via aerospace
# 64 = Spotlight search, 65 = Finder search
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1572864</integer></array><key>type</key><string>standard</string></dict></dict>"

# Disable Mission Control shortcuts that conflict
# 32 = Mission Control (ctrl+up), 33 = App windows (ctrl+down)
# 34 = Move left space (ctrl+left), 35 = Move right space (ctrl+right)
# 79 = Move to space 1 (ctrl+1), etc.

echo "Disabling macOS input source switching (cmd+space conflict)..."
# 60 = input source toggle
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>262144</integer></array><key>type</key><string>standard</string></dict></dict>"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>786432</integer></array><key>type</key><string>standard</string></dict></dict>"

echo "Done. Please log out and log back in for changes to take effect."
echo "To re-enable, go to System Settings > Keyboard > Keyboard Shortcuts"
