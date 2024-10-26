#!/bin/bash

source "$CONFIG_DIR/colors.sh"

COUNT=$(brew outdated | wc -l | tr -d ' ')

COLOR=$RED

case "$COUNT" in
[3-5][0-9])
  COLOR=$NORD_DANGER
  LABEL_PADDING=1
  ;;
[1-2][0-9])
  COLOR=$NORD_WARNING
  LABEL_PADDING=1
  ;;
[1-9])
  COLOR=$WHITE
  LABEL_PADDING=1
  ;;
0)
  COLOR=$WHITE
  LABEL_PADDING=0
  ;;
esac

sketchybar --set $NAME label=$COUNT icon.color=$COLOR label.padding_right=$LABEL_PADDING