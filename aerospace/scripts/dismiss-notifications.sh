#!/usr/bin/env bash
# Dismiss all macOS notifications
# Uses AppleScript to close notification center banners

osascript -e '
tell application "System Events"
    try
        set _groups to groups of UI element 1 of scroll area 1 of group 1 of window "Notification Center" of application process "NotificationCenter"
        repeat with _group in _groups
            set _actions to actions of _group
            repeat with _action in _actions
                if description of _action is "Close" or description of _action is "Clear All" then
                    perform _action
                end if
            end repeat
        end repeat
    end try
end tell
'
