#!/bin/sh

source "$CONFIG_DIR/colors.sh"

MENUS_BINARY="$CONFIG_DIR/helpers/bin/menus"

# Maximum number of menu items
MAX_ITEMS=15
MENU_ITEMS=()
LAST_SPACE_ID=""

# Function to update the app menu
update_app_menu() {
  # Get the space ID of the currently focused app
  current_space_id=$(yabai -m query --windows --window | jq -r '.space')

  # Only update if the space has actually changed
  if [ "$current_space_id" != "$LAST_SPACE_ID" ]; then
    LAST_SPACE_ID="$current_space_id"

    # Remove all existing app menu items and bracket to avoid conflicts
    sketchybar --remove "/app_menu\\..*/" 2>/dev/null || true
    sketchybar --remove app_menu_bracket 2>/dev/null || true

    # Get the latest menu items from the binary
    MENU_ITEMS_STR=($($MENUS_BINARY -l 2>&1))
    MENU_ITEMS=()  # Reset the MENU_ITEMS array

    # Create the menu items and associate them with the current space
    for (( i=1; i<${#MENU_ITEMS_STR[@]}; i++ )); do
      item_label=${MENU_ITEMS_STR[i]}

      sketchybar --add item app_menu.$i left \
        --set app_menu.$i \
          label="$item_label" \
          icon.drawing=off \
          background.color=$TRANSPARENT \
          background.border_color=$NORD_BORDER \
          background.border_width=0 \
          background.corner_radius=5 \
          padding_right=0 \
          click_script="$MENUS_BINARY -s $((i + 1))" \
          space="$current_space_id" \
          script="if [[ \$SENDER == 'mouse.entered' ]]; then 
                    sketchybar --set app_menu.$i background.color=$NORD_BG2
                  elif [[ \$SENDER == 'mouse.exited' ]]; then 
                    sketchybar --set app_menu.$i background.color=$TRANSPARENT
                  fi" \
          --subscribe app_menu.$i mouse.entered mouse.exited
      MENU_ITEMS+=("app_menu.$i")
    done

    MENU_BAR=(
      updates=on
      background.color=$NORD_BG1
      background.corner_radius=5
    )

    # Create the bracket with all items, associating it with the current space
    sketchybar --animate elastic 15 \
          --add bracket app_menu_bracket "${MENU_ITEMS[@]}" \
          --set app_menu_bracket "${MENU_BAR[@]}" \
          space="$current_space_id"
  fi
}

# Function to toggle the app menu visibility
toggle_app_menu() {
  if [[ $(sketchybar --query app_menu.1 | jq -r '.geometry.drawing') == "on" ]]; then
    # Hide the menu
    sketchybar --set "/app_menu\\..*/" drawing=off
  else
    # Show the menu and update the items to reflect the active space
    update_app_menu
    sketchybar --set "/app_menu\\..*/" drawing=on
  fi
}

# Function to handle the front app switch
front_app_switched() {
  # Get the space ID of the current focused app
  space_id=$(yabai -m query --windows --window | jq -r '.space')

  # Get the name of the currently focused app
  focused_app_name=$(yabai -m query --windows --window | jq -r '.app')

  # Update the front app's label, icon, and space association using the focused app name
  sketchybar --animate elastic 15 \
  --set $NAME label="$focused_app_name" icon="$($CONFIG_DIR/plugins/icon_map_fn.sh "$focused_app_name")" \
             space="$space_id" \
             --subscribe $NAME mouse.clicked mouse.entered mouse.exited
             
  # Update the app menu to reflect the new space, ensuring it appears on the correct desktop
  update_app_menu
}

# Main event loop to handle messages
case "$SENDER" in
  "mouse.clicked")
    toggle_app_menu
    ;;
  "front_app_switched" | "space_change")
    front_app_switched
    ;;
  "mouse.entered")
    sketchybar --set $NAME background.color=$NORD_BG2
    ;;
  "mouse.exited")
    sketchybar --set $NAME background.color=$NORD_BG1
    ;;
esac
