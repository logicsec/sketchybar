source "$HOME/.config/sketchybar/icons.sh"

VOLUME=$(osascript -e "output volume of (get volume settings)")
MUTED=$(osascript -e "output muted of (get volume settings)")

if [[ $MUTED != "false" ]]; then
    ICON="$SOUND_MUT_ICON"
    VOLUME=0
else
    case ${VOLUME} in
        100)          ICON="$SOUND_FUL_ICON" ;; # 100%
        [7-9][0-9])   ICON="$SOUND_HIG_ICON" ;; # 70-99%
        [4-6][0-9])   ICON="$SOUND_MID_ICON" ;; # 41-69%
        [1-3][0-9]|40|[1-9]) ICON="$SOUND_LOW_ICON" ;; # 1-40%
        *)            ICON="$SOUND_MUT_ICON"    # 0%
    esac
fi

sketchybar -m \
    --set $NAME icon=$ICON \
    --set $NAME label="$VOLUME%"
