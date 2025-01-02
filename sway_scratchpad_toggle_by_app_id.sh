#!/bin/bash

# Display help
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
	echo '
Receive an app_id as an argument and toggle the given app correctly.

Motivation: When a program window is shown from the scratchpad
and another floating window is focused, the app may appear behind
the active window, requiring manual focus actions. This script
ensures the app toggles correctly, addressing the behavior of
the following command:

	bindsym $mod+p exec swaymsg [app_id="pavucontrol"] scratchpad show || pavucontrol

The script verifies whether the app is focused (post "scratchpad show")
or in the scratchpad, and toggles the app accordingly, ensuring
it appears in front of other open windows.

Example usage in Sway configuration:
# Scripts
set $scratchpad_toggle ~/scripts/sway_scratchpad_toggle_by_app_id.sh

# Shortcuts
bindsym $mod+p exec $scratchpad_toggle pavucontrol || pavucontrol
bindsym $mod+Escape exec $scratchpad_toggle btop || foot --app-id="btop" -e btop

Tested and used in sway 1.10 with wlroots 0.18
'
	exit 0
fi

# Check if app_id was provided
if [[ -z "$1" ]]; then
	echo "Error: Please provide an app_id as the first argument."
    exit 1
fi

APP_ID="$1"

# Check if the app is in the scratchpad or focused
FOCUSED=$(swaymsg -t get_tree | jq -r '
	.. 
	| select( .focused? == true and ( .app_id | test($APP_ID) ) )
	' --arg APP_ID "$APP_ID"
)
# Toggle the application's state in the scratchpad
if [[ "$FOCUSED" != "" ]]; then
	swaymsg [app_id="$APP_ID"] scratchpad show
else
	swaymsg [app_id="$APP_ID"] scratchpad show, focus
fi
