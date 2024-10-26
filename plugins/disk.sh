#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

# Get disk info and format it to match your display style
DISK_INFO=$(df -H / | grep -v Filesystem)
TOTAL_SPACE=$(echo "$DISK_INFO" | awk '{print $2}' | sed 's/[^0-9]*//g')  # Total space in GB
FREE_SPACE=$(echo "$DISK_INFO" | awk '{print $4}' | sed 's/[^0-9]*//g')   # Free space in GB

# Calculate the percentage of free space remaining
PERCENT_REMAINING=$(( (FREE_SPACE * 100) / TOTAL_SPACE ))

echo "$PERCENT_REMAINING"

# Set the color based on percentage remaining
if [ "$PERCENT_REMAINING" -lt 20 ]; then
  COLOR=$NORD_DANGER   # Less than 20% remaining
elif [ "$PERCENT_REMAINING" -lt 50 ]; then
  COLOR=$NORD_WARNING  # Between 20% and 50% remaining
else
  COLOR=$NORD_PRIMARY  # More than 50% remaining
fi

# Format free space display
SPACE_FREE=$(echo "$FREE_SPACE" | xargs printf "%.0fGB")

# Set the label with formatted free space and icon color
sketchybar --set $NAME label="$SPACE_FREE" icon.color="$COLOR"
