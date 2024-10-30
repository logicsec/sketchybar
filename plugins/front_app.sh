#!/bin/sh

source "$CONFIG_DIR/colors.sh"

MENUS_BINARY="$CONFIG_DIR/helpers/bin/menus"

update_app_menu() {
  # Remove existing app menu items
  sketchybar --remove app_menu.* 2>/dev/null || true
  sketchybar --remove app_menu_bracket 2>/dev/null || true

  # Get the latest menu items from the binary and convert it to an array
  MENU_ITEMS_STR=($($MENUS_BINARY -l 2>&1))

  # Define properties for the menu bar
  MENU_BAR=(
    updates=on
  )

  # Loop through each menu item starting from the second one (index 1)
  for (( i=1; i<${#MENU_ITEMS_STR[@]}; i++ )); do
    item_label=${MENU_ITEMS_STR[i]}
    # Create the menu item on the left side
    sketchybar --add item app_menu.$i left \
      --set app_menu.$i \
        label="$item_label" \
        icon.drawing=off \
        background.color=$TRANSPARENT \
        background.border_color=$NORD_BORDER \
        background.border_width=1 \
        background.corner_radius=5 \
        click_script="$MENUS_BINARY -s $i"
  done

  # Create the bracket with all items
  sketchybar --add bracket app_menu_bracket app_menu.* \
    --set app_menu_bracket "${MENU_BAR[@]}"
}

# W I N D O W  T I T L E 
WINDOW_TITLE=$(yabai -m query --windows --window | jq -r '.title')

if [[ $WINDOW_TITLE = "" ]]; then
  WINDOW_TITLE=$(yabai -m query --windows --window | jq -r '.app')
fi

if [[ ${#WINDOW_TITLE} -gt 20 ]]; then
  WINDOW_TITLE=$(echo "$WINDOW_TITLE" | cut -c 1-20)
fi

if [ "$SENDER" = "front_app_switched" ]; then
  sketchybar --set $NAME label="$INFO" icon="$($CONFIG_DIR/plugins/icon_map_fn.sh "$INFO")"
  update_app_menu
fi
