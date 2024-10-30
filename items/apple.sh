#!/bin/bash

# Define the main apple item properties
APPLE=(
  icon=$APPLE_ICON
  icon.color=$RED
  icon.padding_left=10
  icon.padding_right=5
  label.drawing=off
  label.padding_right=0
  background.corner_radius=5
  background.height=25
  click_script="sketchybar -m --set \$NAME popup.drawing=toggle" \
  popup.background.border_width=1 \
  popup.background.border_color=$NORD_BORDER \
  popup.background.corner_radius=2 \
  popup.background.color=$BG_PRI_COLR \
  popup.background.drawing=on \
  popup.y_offset=0 \
  popup.blur_radius=10
)

# Define the menu items in an array for easier management
APPLE_MENU_ITEMS=(
  "Reload Sketchybar:sketchybar --reload && sketchybar -m --set apple popup.drawing=off:􀺽"
)

# Function to add menu items dynamically
add_menu_items() {
  for item in "${APPLE_MENU_ITEMS[@]}"; do
    IFS=":" read -r label command icon <<< "$item"
    
    sketchybar --add item "apple.$(echo "$label" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')" popup.apple \
               --set "apple.$(echo "$label" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')" \
               icon="$icon" \
               label="$label" \
               click_script="$command"
  done
}

# Add the apple item to the left side
sketchybar --add item apple left \
           --set apple "${APPLE[@]}" \
           --subscribe apple mouse.exited.global

# Close the popup if clicked outside the bar
sketchybar --add event global-exit "mouse.exited.global" \
           --subscribe apple global-exit \
           --set apple script="sketchybar --set apple popup.drawing=off"


# Add the popup items to the sketchybar config
add_menu_items