#!/bin/bash

source "$HOME/.config/sketchybar/icons.sh"

# Adding a network item to SketchyBar
sketchybar --add item net left \
           --set net script="$PLUGIN_DIR/network.sh" \
                     updates=on \
                     label.drawing=off \
                     icon.drawing=off \
                     icon.color=$FG1 \
                     icon=$NET_OFF   # Set a default icon

# Subscribe to wifi_change to get updates
sketchybar --subscribe net wifi_change