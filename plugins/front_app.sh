#!/bin/sh

source "$CONFIG_DIR/colors.sh"

MENUS_BINARY="$CONFIG_DIR/helpers/bin/menus"

# Maximum number of menu items
MAX_ITEMS=15
MENU_ITEMS=()

# Function to update the app menu
update_app_menu() {
  # Remove existing app menu items
  sketchybar --remove app_menu.* 2>/dev/null || true
  sketchybar --remove app_menu_bracket 2>/dev/null || true

  # Get the latest menu items from the binary
  MENU_ITEMS_STR=($($MENUS_BINARY -l 2>&1))

  # Create the menu items
  for (( i=1; i<${#MENU_ITEMS_STR[@]}; i++ )); do
    item_label=${MENU_ITEMS_STR[i]}
    sketchybar --add item app_menu.$i left \
      --set app_menu.$i \
        label="$item_label" \
        icon.drawing=off \
        background.color=$TRANSPARENT \
        background.border_color=$NORD_BORDER \
        background.border_width=1 \
        background.corner_radius=5 \
        click_script="$MENUS_BINARY -s $i"
    MENU_ITEMS+=("app_menu.$i")
  done

  # Create the bracket with all items
  sketchybar --add bracket app_menu_bracket "${MENU_ITEMS[@]}" \
    --set app_menu_bracket updates=on
}

# Function to toggle the app menu visibility
toggle_app_menu() {
  # Check if the menu bracket's geometry is currently drawn
  if [[ $(sketchybar --query app_menu.1 | jq -r '.geometry.drawing') == "on" ]]; then
    # Hide the menu
    sketchybar --set "/app_menu\\..*/" drawing=off
  else
    # Show the menu
    update_app_menu
    sketchybar --set "/app_menu\\..*/" drawing=on
  fi
}

# Function to handle the front app switch
front_app_switched() {
  sketchybar --set $NAME label="$INFO" icon="$($CONFIG_DIR/plugins/icon_map_fn.sh "$INFO")" \
              --subscribe $NAME mouse.clicked
  update_app_menu
}

# Main event loop to handle messages
case "$SENDER" in
  "mouse.clicked")
    toggle_app_menu
    ;;
  "front_app_switched")
    front_app_switched
    ;;
esac
