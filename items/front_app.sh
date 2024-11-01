#!/bin/bash

# Front app configuration
FRONT_APP=(
  label.font="$FONT:SemiBold:12.0"
  icon.font="sketchybar-app-font:Regular:14.0"
  icon.color=$PEACH
  label.color=$WHITE
  background.color=$NORD_BG1
  background.corner_radius=5
  background.height=25
  background.padding_left=5
  background.padding_right=5
  padding_left=30
  padding_right=-6
  script="$PLUGIN_DIR/front_app.sh"
)

# Add the front_app item
sketchybar --add item front_app left \
           --set front_app "${FRONT_APP[@]}" \
           --subscribe front_app front_app_switched space_change