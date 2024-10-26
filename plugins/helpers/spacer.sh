#!/bin/bash

# Create a helper function for adding spacers
add_spacer() {
    local position=${1:-right}    # Default position is right
    local width=${2:-10}          # Default width is 10
    local name="spacer_$(date +%s%N)"  # Unique name using timestamp

    # Configure the spacer
    SPACER=(
        width=$width
        background.drawing=off
    )

    # Add the spacer item
    sketchybar --add item $name $position                \
                --set spacer background.drawing=off    \
                width=$width                   \
    
    # Return the name of the created spacer (optional)
    echo "$name"
}
