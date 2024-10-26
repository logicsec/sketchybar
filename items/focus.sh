#!/bin/bash

focus=(
    update_freq=5
    script="$PLUGIN_DIR/focus.sh"
    label="No Focus" \
    label.color=$NORD_PRIMARY \
    background.color=$NORD_BG1 \
    background.corner_radius=5 \
    background.height=25 \
    background.padding_left=5 \
    background.padding_right=5 \
    background.border_color=$NORD_BORDER \
    background.border_width=1
    background.image.drawing=off
    icon.drawing=off
    background.image="SFSymbol.person.lanyardcard.fill"
    background.drawing=on
    padding_right=10
)

sketchybar --add item focus_mode left \
           --set focus_mode "${focus[@]}" \
           --subscribe focus_mode custom_event