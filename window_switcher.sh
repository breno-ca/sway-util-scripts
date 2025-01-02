#!/bin/bash

# Display help
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo '
Creates a window switcher for SwayWM using fuzzel in dmenu mode.

Motivation: SwayWM does not have a built-in window switcher.
This script lists open windows, grouping them by workspace or,
and allows selecting a window to focus on. The script also supports
custom icons and workspace renaming for a better user experience.

Example usage in Sway configuration:

	bindsym Alt+Tab exec ~/scripts/window_switcher.sh

Requirements:
- jq: to parse swaymsg output
- fuzzel: to create the window switcher

Note: The script was designed with fuzzel in mind but can be 
adjusted to work with rofi by modifying the dmenu item output.

References:
- https://gist.github.com/lbonn/89d064cde963cfbacabd77e0d3801398
- https://www.reddit.com/r/swaywm/comments/pyq5mm/looking_for_a_window_switcher/
- https://github.com/swaywm/sway/issues/4121
'
    exit 0
fi

# Parse the Sway tree to generate a formatted list of windows for fuzzel.
selected_window=$( swaymsg -t get_tree | jq -r '
	..
	# Get workspaces and customize workspace names
	| objects | select(.type == "workspace") as $workspace
	| ( if $workspace.name == "__i3_scratch" 
		then "-" else $workspace.name end 
	  ) as $ws_name 

    | ..
	# Get opened apps and set "focused" decoration
    | objects | select(has("app_id"))
	| (if .focused == true then "🟢" else "" end) as $selected

	# Exclude apps from list
	| select(.app_id == null or (.app_id | test("pavucontrol") | not))
	
	# Manually set icons to fix cases where they are not displayed
	| ( "vivaldi-pjibgclleladliembfgfagdaldikeohf-Default" ) as $spotify
	| ( if .name != null and (.name | test("Spotify")) then $spotify
		elif .app_id == "Firefox" then "firefox" 
		else .app_id // .window_properties.class // .name end
	  ) as $icon
	
	# Fix for displaying app_id when it is null
	| ( if .app_id == null and (.name | test("Spotify")) then "Spotify" 
		else .name end 
	  ) as $app_id

	# Set dmenu item format (keep the icon separated from the rest)
	# Output ex: 📂 (101) [1] 🟢File Explorer 
	| "(\(.id)) [\($ws_name)] \($selected)\($app_id)" +
	  "\u0000icon\u001f\($icon)"' \
	| fuzzel -d -w 50
)

# Focus the selected window.
if [ "$selected_window" != "" ]; then
	window_id=$(echo "$selected_window" | sed 's/.*(\([[:digit:]]*\)).*/\1/')
	swaymsg [con_id="$window_id"] focus
fi
