#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Get the Messages database path
DB_PATH="$HOME/Library/Messages/chat.db"

# Check if the database exists and get unread iMessage count
if [ -f "$DB_PATH" ]; then
    COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) as unread FROM message JOIN chat_message_join ON chat_message_join.message_id = message.ROWID JOIN chat ON chat.ROWID = chat_message_join.chat_id WHERE message.is_from_me = 0 AND message.is_read = 0"
    )
else
    COUNT=0
fi

# Default color
COLOR=$RED

# Color logic based on unread count
case "$COUNT" in
    # 30-59 unread messages
    [3-5][0-9])
        ICON_COLOR=$RED
        LABEL_COLOR=$WHITE
        LABEL_PADDING=1
        ;;
    # 10-29 unread messages
    [1-2][0-9])
        ICON_COLOR=$YELLOW
        LABEL_COLOR=$WHITE
        LABEL_PADDING=1
        ;;
    # 1-9 unread messages
    [1-9])
        ICON_COLOR=$BLUE
        LABEL_COLOR=$WHITE
        LABEL_PADDING=1
        ;;
    # No unread messages
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
