#!/bin/bash

media=(
    script="$PLUGIN_DIR/media.sh"
    updates=on
    background.color=$NORD_BG1
    background.corner_radius=5
    background.height=25
    background.padding_left=5
    background.padding_right=5
    background.border_color=$NORD_BORDER
    background.border_width=1
    padding_right=10
    width=170          # Add fixed width
    label.width=150    # Add fixed label width
    icon.width=20      # Add fixed icon width
    align=left         # Ensure left alignment
)

sketchybar --add item media right \
           --set media "${media[@]}" \
           --subscribe media media_change