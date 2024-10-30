#!/bin/bash

# Disk configuration
DISK=(
  update_freq=30
  label.padding_left=1
  label.padding_right=1
  icon.font="$FONT:Regular:16.0"
  icon=􀥾
  icon.padding_left=2
  icon.padding_right=5
  icon.color=$YELLOW
  background.color=$TRANSPARENT
  script="$PLUGIN_DIR/disk.sh"
)

# Memory configuration
MEMORY=(
  update_freq=30
  label.padding_left=1
  label.padding_right=1
  icon.font="$FONT:Regular:16.0"
  icon=􀫦
  icon.padding_left=2
  icon.padding_right=5
  icon.color=$BLUE
  background.color=$TRANSPARENT
  script="$PLUGIN_DIR/memory.sh"
)

# CPU configuration
CPU=(
  update_freq=30
  icon.font="$FONT:Regular:16.0"
  icon=􀫥
  icon.padding_left=2
  icon.padding_right=5
  icon.color=$RED
  label.padding_left=1
  label.padding_right=1
  background.color=$TRANSPARENT
  script="$PLUGIN_DIR/cpu.sh"
)

WEATHER=(
  update_freq=120
  icon.font="$ICON_FONT:Regular:16.0"
  icon.color=$GREEN
  icon.padding_left=4
  icon.padding_right=5
  label.color=$WHITE
  label.padding_left=1
  label.padding_right=1
  background.color=$TRANSPARENT
  script="$PLUGIN_DIR/weather.sh"
)

# Add all items first
sketchybar --add item disk right \
           --set disk "${DISK[@]}" \
           --add item memory right \
           --set memory "${MEMORY[@]}" \
           --add item cpu right \
           --set cpu "${CPU[@]}" \
           --add item weather right \
           --set weather "${WEATHER[@]}" \
           --subscribe sound volume_change \
           --subscribe battery system_woke power_source_change

# Create the bracket with metrics items
sketchybar --add bracket metrics weather disk memory cpu \
           --set metrics background.color=$NORD_BG1 \
                        background.corner_radius=5 \
                        background.height=25 \
                        background.padding_left=5 \
                        background.padding_right=5
