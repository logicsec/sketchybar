#!/usr/bin/env bash

# Source your color configuration file
source "$HOME/.config/sketchybar/colors.sh"  # Adjust this path as necessary

# Function to read JSON file and extract values using jq
get_json() {
    local path="$1"
    jq '.' "$path"
}

# Get assertions and configurations
assertions=$(get_json ~/Library/DoNotDisturb/DB/Assertions.json)
config=$(get_json ~/Library/DoNotDisturb/DB/ModeConfigurations.json)

# Default focus
focus="No Focus"

# Check if focus is set manually
if [[ $(echo "$assertions" | jq '.data[0].storeAssertionRecords | length') -gt 0 ]]; then
    modeid=$(echo "$assertions" | jq -r '.data[0].storeAssertionRecords[0].assertionDetails.assertionDetailsModeIdentifier')
    focus=$(echo "$config" | jq -r ".data[0].modeConfigurations[\"$modeid\"].mode.name")
else
    # Focus set by trigger
    now=$(( $(date +%H) * 60 + $(date +%M) ))

    for modeid in $(echo "$config" | jq -r '.data[0].modeConfigurations | keys[]'); do
        triggers=$(echo "$config" | jq -r ".data[0].modeConfigurations[\"$modeid\"].triggers.triggers[0]")

        if [[ "$triggers" != "null" ]] && [[ $(echo "$triggers" | jq -r '.enabledSetting') -eq 2 ]]; then
            start=$(( $(echo "$triggers" | jq -r '.timePeriodStartTimeHour') * 60 + $(echo "$triggers" | jq -r '.timePeriodStartTimeMinute') ))
            end=$(( $(echo "$triggers" | jq -r '.timePeriodEndTimeHour') * 60 + $(echo "$triggers" | jq -r '.timePeriodEndTimeMinute') ))

            if [[ $start -lt $end ]]; then
                if [[ $now -ge $start && $now -lt $end ]]; then
                    focus=$(echo "$config" | jq -r ".data[0].modeConfigurations[\"$modeid\"].mode.name")
                fi
            else
                # Includes midnight
                if [[ $now -ge $start || $now -lt $end ]]; then
                    focus=$(echo "$config" | jq -r ".data[0].modeConfigurations[\"$modeid\"].mode.name")
                fi
            fi
        fi
    done
fi

# Initialize image variable
BACKGROUND_IMAGE=""

# Fetch the background image based on the focus mode
if [ "$focus" != "No Focus" ]; then
    # Retrieve the mode ID for the current focus mode
    modeid=$(echo "$config" | jq -r ".data[0].modeConfigurations | to_entries[] | select(.value.mode.name==\"$focus\") | .key")
    if [ -n "$modeid" ]; then
        SYMBOL_NAME=$(echo "$config" | jq -r ".data[0].modeConfigurations[\"$modeid\"].mode.symbolImageName")  # Get the SF Symbol name for background
        BACKGROUND_IMAGE="SFSymbol.$SYMBOL_NAME"  # Combine with app ID
    fi
fi

# Set the default image if none was found
if [ -z "$BACKGROUND_IMAGE" ]; then
    BACKGROUND_IMAGE="SFSymbol.person.lanyardcard.fill"  # Default SF Symbol if not found
fi

# Update the SketchyBar item with the label and background image
sketchybar --set focus_mode label="$focus" background.color="$NORD_BG1"
