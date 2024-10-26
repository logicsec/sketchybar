#!/bin/sh

properties=(
  label.y_offset=0
  label.padding_left=4
  label.padding_right=10
  icon.padding_left=10
  width=175
)

#FIXME: show second page.
sketchybar --add item apple.uname popup.apple \
  --set apple.uname label="$(uname -s -r -m)" \
    label.padding_left=10 \
    label.padding_right=10 \
--add item apple.sw_vers popup.sw_vers \ 
  --set apple.sw_vers label="$(sw_vers | awk '/ProductName/ {printf $2" "} /ProductVersion/ {printf $2" "} /BuildVersion/ {print "(" $2")"}')" \
    label.padding_left=10 \
    label.padding_right=10

    #icon=$APPLE "${properties[@]}" ]

# Handle mouse events
case "$SENDER" in
  "mouse.entered")
    sketchybar --set $NAME popup.drawing=on
    
    ;;
  "mouse.exited" | "mouse.exited.global")
    sketchybar --set $NAME popup.drawing=off
    
    # unhighlight effect
    sketchybar --set $NAME icon.highlight=off label.highlight=off
    ;;
  "mouse.clicked")
    # clicked effect
    sketchybar --set $NAME
    sketchybar --set $NAME
    sketchybar --set $NAME popup.drawing=off
    ;;
  "routine")
    ;;
esac