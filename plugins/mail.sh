#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Get the unread email count using corrected AppleScript
COUNT=$(osascript -e '
tell application "Mail"
    if it is running then
        try
            count of (messages of inbox whose read status is false)
        on error
            return 0
        end try
    else
        return 0
    end if
end tell
')

# Default color
COLOR=$RED

# Color logic based on unread count
case "$COUNT" in
    # 30-59 unread emails
    [3-5][0-9])
        ICON_COLOR=$RED
        LABEL_COLOR=$WHITE
        LABEL_PADDING=1
        ;;
    # 10-29 unread emails
    [1-2][0-9])
        ICON_COLOR=$YELLOW
        LABEL_COLOR=$WHITE
        LABEL_PADDING=1
        ;;
    # 1-9 unread emails
    [1-9])
        ICON_COLOR=$BLUE
        LABEL_COLOR=$WHITE
        LABEL_PADDING=1
        ;;
    # No unread emails
    0)
        ICON_COLOR=$GREEN
        LABEL_COLOR=$WHITE
        LABEL_PADDING=0
        ;;
    # Error case
    *)
        ICON_COLOR=$RED
        LABEL_COLOR=$WHITE
        COUNT="!"  # Show error indicator
        LABEL_PADDING=1
        ;;
esac

# Update the SketchyBar item
sketchybar --set $NAME \
    label="$COUNT" \
    icon.color="$ICON_COLOR" \
    label.color="$LABEL_COLOR" \
    label.padding_right=$LABEL_PADDING