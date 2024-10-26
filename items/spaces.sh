#!/bin/bash

# Colors
INACTIVE_COLOR="$NORD_BG1"  # Translucent white for inactive
ACTIVE_COLOR="$NORD_BG2"      # Solid white for active

# Dimensions
SPACE_WIDTH=11
SPACE_HEIGHT=11
SPACE_MARGIN=5  # Margin between space indicators
BACKGROUND_PADDING=8  # Padding inside background container

# Common settings for all spaces
SPACE=(
  update_freq=5
  background.height=$SPACE_HEIGHT
  background.drawing=on
  background.color=$INACTIVE_COLOR
  background.corner_radius=$(( $SPACE_HEIGHT / 2 ))
  background.padding_right=0  # Remove padding right since we're using margins
  icon.drawing=off
  label.drawing=off
  script="$PLUGIN_DIR/space.sh"
)

SPACES_BAR=(
  update_freq=5
  background.color=$TRANSPARENT
  background.corner_radius=$(( $SPACE_HEIGHT / 2 ))
  background.height=25
  background.padding_left=5
  background.padding_right=5
)

function create_space_indicators() {
  # First, remove all existing space-related items
  sketchybar --remove '/space\..*/' 2>/dev/null || true
  sketchybar --remove '/space_margin\..*/' 2>/dev/null || true
  sketchybar --remove '/spaces_bracket/' 2>/dev/null || true

  # Query all spaces
  SPACES=$(yabai -m query --spaces)
  
  # Loop through each display dynamically
  ALL_ITEMS=()
  
  for display in $(yabai -m query --displays | jq -r '.[].index'); do
    # Get spaces for the current display
    DISPLAY_SPACES=($(echo "$SPACES" | jq -r --argjson display "$display" \
                     '.[] | select(.display == $display) | .index'))
    
    # Calculate total spaces for this display
    total_spaces=${#DISPLAY_SPACES[@]}
    
    for ((i = 0; i < total_spaces; i++)); do
      sid=${DISPLAY_SPACES[$i]}
      
      # Create the space indicator
      sketchybar --add space space.$sid left \
                 --set space.$sid associated_space=$sid \
                                 "${SPACE[@]}" \
                                 width=$SPACE_WIDTH
      
      # Add to items list
      ALL_ITEMS+=(space.$sid)
      
      # Add margin if not the last space on this display
      if [ $i -lt $((total_spaces - 1)) ]; then
        # Create margin item
        sketchybar --add item space_margin.$sid left \
                   --set space_margin.$sid width=$SPACE_MARGIN \
                                           background.drawing=off
        ALL_ITEMS+=(space_margin.$sid)
      fi
    done
  done

  # Create the bracket with all items
  [ ${#ALL_ITEMS[@]} -gt 0 ] && \
  sketchybar --add bracket spaces_bracket "${ALL_ITEMS[@]}" \
             --set spaces_bracket "${SPACES_BAR[@]}"
}

# Initial creation of space indicators
create_space_indicators

# Function to handle space changes
function space_change_handler() {
  create_space_indicators
}

# Update spaces on workspace change
sketchybar --subscribe spaces space_change space_change_handler

# Handle mission-control events
yabai -m signal --add event=mission_control_exit action="sketchybar --trigger space_change"