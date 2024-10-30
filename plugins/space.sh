#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"

# Colors
INACTIVE_COLOR="$NORD_BG1"
ACTIVE_COLOR="$NORD_BG2"

# Dimensions
SPACE_WIDTH=11
SPACE_HEIGHT=11
ACTIVE_SPACE_WIDTH=30
SPACE_MARGIN=5

update_space() {
  local SID=$1
  local SELECTED=$2
  local OCCUPIED=$3
  
  # Get current display
  local DISPLAY=$(yabai -m query --spaces --space $SID | jq -r '.display')
  
  # Get all spaces on current display
  local SPACES=($(yabai -m query --spaces | jq -r --argjson display "$DISPLAY" \
                 '.[] | select(.display == $display) | .index'))
  
  # Determine if this is the last space on the display
  local IS_LAST=false
  [ "${SPACES[-1]}" = "$SID" ] && IS_LAST=true
  
  if [ "$SELECTED" = "true" ]; then
    sketchybar --animate tanh 20 \
               --set space.$SID background.color=$ACTIVE_COLOR \
                               width=$ACTIVE_SPACE_WIDTH \
                               background.corner_radius=$(( $SPACE_HEIGHT / 2 ))
  else
    sketchybar --animate tanh 20 \
               --set space.$SID background.color=$INACTIVE_COLOR \
                               width=$SPACE_WIDTH \
                               background.corner_radius=$(( $SPACE_HEIGHT / 2 ))
  fi
  
  # Only update margin if not the last space
  if [ "$IS_LAST" = "false" ]; then
    sketchybar --set space_margin.$SID width=$SPACE_MARGIN
  fi
}

case "$SENDER" in
  "space_change")
    DISPLAY_INDEX=$(yabai -m query --displays --display | jq -r '.index')
    SPACES=($(yabai -m query --spaces | jq -r --argjson display "$DISPLAY_INDEX" \
             '.[] | select(.display == $display) | .index'))
    
    for space in "${SPACES[@]}"; do
      SELECTED=$(yabai -m query --spaces --space $space | jq -r '.["is-visible"]')
      OCCUPIED=$(yabai -m query --spaces --space $space | jq -r '.windows != []')
      update_space $space $SELECTED $OCCUPIED
    done
    ;;
  *)
    SELECTED=$(yabai -m query --spaces --space $SID | jq -r '.["is-visible"]')
    OCCUPIED=$(yabai -m query --spaces --space $SID | jq -r '.windows != []')
    update_space $SID $SELECTED $OCCUPIED
    ;;
esac