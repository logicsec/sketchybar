#!/bin/bash

source "$PLUGIN_DIR/helpers/spacer.sh"


TIME=(
  update_freq=10
  icon.drawing=off
  icon.padding_left=8
  label.color=$FG2
  label.align=right
  label.padding_right=12
  label.padding_left=12
  label.font="$FONT:Bold:12.0"
  background.color=$RED
  background.padding_right=0
  background.corner_radius=5
  script="$PLUGIN_DIR/time.sh"
)

DATE=(
  update_freq=10
  icon.drawing=off
  icon.padding_left=8
  label.color=$WHITE
  label.align=right
  label.padding_right=8
  label.font="$FONT:Bold:12.0"
  background.color=$TRANSPARENT
  background.padding_right=0
  background.corner_radius=0
  script="$PLUGIN_DIR/date.sh"
  click_script="$PLUGIN_DIR/launchers/open_calendar.sh"
)

DATETIME_BAR=(
  background.color=$NORD_BG1
  background.corner_radius=5
  background.height=25
  background.padding_left=5
  background.padding_right=5
)


# Add items in right-to-left order
sketchybar --add item time right \
           --add item date right \
           --add item spacer_datetime right                \
          --set spacer_datetime background.drawing=off    \
          width=10 \
           --set time "${TIME[@]}" \
           --set date "${DATE[@]}"

# Create bracket with items in left-to-right order
sketchybar --add bracket datetime date time \
           --set datetime "${DATETIME_BAR[@]}" \
                        background.border_color=$NORD_BORDER \
                        background.border_width=1