#!/bin/bash

# Get current user's profile picture - try multiple possible locations
CURRENT_USER=$(whoami)
PROFILE_PIC="/Users/$CURRENT_USER/Pictures/profile.jpg"

# Define the main profile item properties
PROFILE=(
  background.image.string="$PROFILE_PIC"
  background.image.corner_radius=8
  background.image.scale=0.12
  background.image.drawing=on
  background.drawing=on
  background.padding_left=15
  background.padding_right=5
  icon.drawing=off   
  label.drawing=off
  click_script="get_mouse_position() { osascript -e 'tell application \"System Events\" to get the position of the front window of (first application process whose frontmost is true)'; }; pos=(\$(get_mouse_position)); sketchybar -m --set \$NAME popup.x=\${pos[0]} popup.y=\${pos[1]} popup.drawing=toggle" \
  popup.background.border_width=0 \
  popup.background.border_color=$NORD_BORDER \
  popup.background.corner_radius=0 \
  popup.background.color=$BG_PRI_COLR \
  popup.background.drawing=on \
  popup.background.padding_right=0 \
  popup.align=right \
  popup.y_offset=0 \
  popup.blur_radius=10
)

# Define the popup menu items similar to the macOS menu
PROFILE_MENU_ITEMS=(
  "About This Mac:open -a 'About This Mac':"
  "System Settings:open -a 'System Settings':"
  "App Store:open -a 'App Store':"
  "Recent Items:open -a 'Recent Items':"
  "Force Quit:osascript -e 'tell application \"System Events\" to force quit':"
  "Sleep:osascript -e 'tell application \"System Events\" to sleep':"
  "Restart:osascript -e 'tell application \"System Events\" to restart':"
  "Shut Down:osascript -e 'tell application \"System Events\" to shut down':"
  "Lock Screen:open -a '/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/LockScreen':"
  "Log Out $CURRENT_USER:osascript -e 'tell application \"System Events\" to log out':"
)

# Function to add menu items dynamically and close popup after clicking an item
add_menu_items() {
  for item in "${PROFILE_MENU_ITEMS[@]}"; do
    IFS=":" read -r label command icon <<< "$item"
    item_name="profile.$(echo "$label" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')"
    
    sketchybar --add item "$item_name" popup.profile \
               --set "$item_name" \
               icon="$icon" \
               label="$label" \
               click_script="$command; sketchybar --set profile popup.drawing=off" \
               label.font="SF Pro Text:Bold:14.0" \
               background.padding_left=10 \
               background.padding_right=10 \
               background.drawing=on
  done
}

# Add the profile item to the right side
sketchybar --add item profile right \
           --set profile "${PROFILE[@]}" \
           --subscribe profile mouse.exited.global

# Close the popup if clicked outside the bar
sketchybar --add event global-exit "mouse.exited.global" \
           --subscribe profile global-exit \
           --set profile script="sketchybar --set profile popup.drawing=off"

# Add the popup items to the sketchybar config
add_menu_items
