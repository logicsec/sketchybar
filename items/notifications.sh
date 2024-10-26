#!/bin/bash

source "$PLUGIN_DIR/helpers/spacer.sh"

brew=(
  icon=􀐚
  icon.color=$WHITE
  icon.padding_left=2
  icon.padding_right=5
  icon.font="$FONT:Regular:16.0"
  label=0
  label.padding_left=1
  label.padding_right=1
  background.color=$TRANSPARENT
  background.corner_radius=5
  background.height=25
  background.padding_left=5
  background.padding_right=5
  script="$PLUGIN_DIR/brew.sh"
  click_script="brew update && brew upgrade"
)

mail=(
  update_freq=10
  icon=􀍕
  icon.color=$WHITE
  icon.padding_left=2
  icon.padding_right=5
  icon.font="$FONT:Regular:16.0"
  label=0
  label.padding_left=1
  label.padding_right=1
  background.color=$TRANSPARENT
  background.corner_radius=5
  background.height=25
  background.padding_left=5
  background.padding_right=5
  script="$PLUGIN_DIR/mail.sh"
  click_script="$PLUGIN_DIR/launchers/open_mail.sh"
)

messages=(
  update_freq=10
  icon=􀌤
  icon.color=$WHITE
  icon.padding_left=2
  icon.padding_right=5
  icon.font="$FONT:Regular:16.0"
  label=0
  label.padding_left=1
  label.padding_right=1
  background.color=$TRANSPARENT
  background.corner_radius=5
  background.height=25
  background.padding_left=5
  background.padding_right=5
  script="$PLUGIN_DIR/messages.sh"
  click_script="$PLUGIN_DIR/launchers/open_messages.sh"
)

# Battery configuration
BATTERY=(
  update_freq=120
  icon.color=$NORD_PRIMARY
  icon.padding_left=2
  icon.padding_right=5
  icon.font="$FONT:Regular:16.0"
  label.color=$WHITE
  label.padding_left=1
  label.padding_right=1
  background.color=$TRANSPARENT
  script="$PLUGIN_DIR/battery.sh"
)

# Sound configuration
SOUND=(
  icon.color=$NORD_FROST_9
  icon.padding_left=2
  icon.padding_right=5
  icon.font="$FONT:Regular:16.0"
  background.color=$TRANSPARENT
  label.padding_left=1
  label.padding_right=1
  script="$PLUGIN_DIR/sound.sh"
  click_script="$PLUGIN_DIR/sound_click.sh"
)


# Add brew update, mail unread count, and messages items
sketchybar --add event brew_update right \
           --add event mail_check \
           --add event messages_check \
           --add item brew right \
           --set brew "${brew[@]}" \
           --subscribe brew brew_update \
           --add item mail right \
           --set mail "${mail[@]}" \
           --add item messages right \
           --set messages "${messages[@]}" \
           --add item spacer_notifications right \
           --set spacer_notifications background.drawing=off \
           width=10 \
           --subscribe mail mail_check \
           --subscribe messages messages_check

# Create the bracket to group brew, mail, and messages items
sketchybar --add bracket notifications brew mail messages \
           --set notifications background.color=$NORD_BG1 \
                        background.corner_radius=5 \
                        background.height=25 \
                        background.padding_left=5 \
                        background.padding_right=5 \
                        background.border_color=$NORD_BORDER \
                        background.border_width=1 

sketchybar --add item battery right \
           --set battery "${BATTERY[@]}" \
           --add item sound right \
           --set sound "${SOUND[@]}" \
           --add item spacer_notifications_batvol right \
           --set spacer_notifications_batvol background.drawing=off \
           width=10  

sketchybar --add bracket notifications_batvol battery sound \
           --set notifications_batvol background.color=$NORD_BG1 \
                        background.corner_radius=5 \
                        background.height=25 \
                        background.padding_left=5 \
                        background.padding_right=5 \
                        background.border_color=$NORD_BORDER \
                        background.border_width=1
