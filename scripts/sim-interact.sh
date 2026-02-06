#!/bin/bash
# sim-interact.sh - Standardized iOS Simulator interaction library
# Source this file to get reliable tap, swipe, type, and long-press functions.
#
# Usage:
#   source scripts/sim-interact.sh
#   sim_tap 200 400          # Tap at device coords (x, y)
#   sim_long_press 200 400   # Long press at device coords
#   sim_swipe up             # Swipe in direction (up/down/left/right)
#   sim_type "hello"         # Type text into focused field
#   sim_key "return"         # Press a key (return, escape, tab, delete)
#
# Device coordinate system: iPhone 16 Pro @ 1x = 402x874 viewport
# Origin (0,0) is top-left of the device screen content area.

# Verify cliclick is installed
if ! command -v cliclick &>/dev/null; then
    echo "ERROR: cliclick is required. Install with: brew install cliclick" >&2
    return 1 2>/dev/null || exit 1
fi

# --- Internal: map device coords to screen coords ---
_sim_screen_coords() {
    local DX=$1 DY=$2
    osascript -e "
tell application \"System Events\"
    tell process \"Simulator\"
        set winPos to position of window 1
        set winSize to size of window 1
        set contentH to (item 2 of winSize) - 28
        set padX to ((item 1 of winSize) - 402) / 2
        set padY to (contentH - 874) / 2
        set baseX to round ((item 1 of winPos) + padX + $DX)
        set baseY to round ((item 2 of winPos) + 28 + padY + $DY)
        return (baseX as text) & \" \" & (baseY as text)
    end tell
end tell
" 2>/dev/null
}

# --- Internal: ensure Simulator is frontmost ---
_sim_focus() {
    osascript -e '
tell application "System Events"
    tell process "Simulator"
        set frontmost to true
    end tell
end tell
' 2>/dev/null
    sleep 0.15
}

# --- Public API ---

# Tap at device coordinates
# Usage: sim_tap <device_x> <device_y>
sim_tap() {
    local DX=$1 DY=$2
    _sim_focus
    local COORDS=$(_sim_screen_coords "$DX" "$DY")
    local SX=$(echo "$COORDS" | awk '{print $1}')
    local SY=$(echo "$COORDS" | awk '{print $2}')
    cliclick c:"$SX","$SY"
}

# Long press at device coordinates (for context menus)
# Usage: sim_long_press <device_x> <device_y> [duration_ms]
sim_long_press() {
    local DX=$1 DY=$2 DUR=${3:-800}
    _sim_focus
    local COORDS=$(_sim_screen_coords "$DX" "$DY")
    local SX=$(echo "$COORDS" | awk '{print $1}')
    local SY=$(echo "$COORDS" | awk '{print $2}')
    cliclick dd:"$SX","$SY"
    sleep $(echo "scale=3; $DUR/1000" | bc)
    cliclick du:"$SX","$SY"
}

# Swipe in a direction from center (or custom origin)
# Usage: sim_swipe <direction> [origin_x] [origin_y]
# direction: up, down, left, right
# Uses slow incremental drag (50px steps, 100ms delay) which iOS simulator requires
sim_swipe() {
    local DIR=$1
    local DX=${2:-201} DY=${3:-437}
    _sim_focus
    local COORDS=$(_sim_screen_coords "$DX" "$DY")
    local SX=$(echo "$COORDS" | awk '{print $1}')
    local SY=$(echo "$COORDS" | awk '{print $2}')

    local STEPS=6
    local STEP_PX=50
    local STEP_DELAY=0.1

    cliclick dd:"$SX","$SY"
    sleep 0.05

    case $DIR in
        up)
            for i in $(seq 1 $STEPS); do
                local NY=$((SY - i * STEP_PX))
                cliclick dm:"$SX","$NY"
                sleep $STEP_DELAY
            done
            cliclick du:"$SX",$((SY - STEPS * STEP_PX))
            ;;
        down)
            for i in $(seq 1 $STEPS); do
                local NY=$((SY + i * STEP_PX))
                cliclick dm:"$SX","$NY"
                sleep $STEP_DELAY
            done
            cliclick du:"$SX",$((SY + STEPS * STEP_PX))
            ;;
        left)
            for i in $(seq 1 $STEPS); do
                local NX=$((SX - i * STEP_PX))
                cliclick dm:"$NX","$SY"
                sleep $STEP_DELAY
            done
            cliclick du:$((SX - STEPS * STEP_PX)),"$SY"
            ;;
        right)
            for i in $(seq 1 $STEPS); do
                local NX=$((SX + i * STEP_PX))
                cliclick dm:"$NX","$SY"
                sleep $STEP_DELAY
            done
            cliclick du:$((SX + STEPS * STEP_PX)),"$SY"
            ;;
        *)
            echo "ERROR: Unknown direction '$DIR'. Use: up, down, left, right" >&2
            return 1
            ;;
    esac
}

# Type text into a focused field
# Usage: sim_type "text to type"
sim_type() {
    local TEXT="$1"
    _sim_focus
    osascript -e "
tell application \"System Events\"
    tell process \"Simulator\"
        keystroke \"$TEXT\"
    end tell
end tell
" 2>/dev/null
}

# Press a special key
# Usage: sim_key <key_name>
# key_name: return, escape, tab, delete, space
sim_key() {
    local KEY=$1
    _sim_focus
    local KEY_CODE
    case $KEY in
        return)  KEY_CODE=36 ;;
        escape)  KEY_CODE=53 ;;
        tab)     KEY_CODE=48 ;;
        delete)  KEY_CODE=51 ;;
        space)   KEY_CODE=49 ;;
        *)
            echo "ERROR: Unknown key '$KEY'. Use: return, escape, tab, delete, space" >&2
            return 1
            ;;
    esac
    osascript -e "
tell application \"System Events\"
    tell process \"Simulator\"
        key code $KEY_CODE
    end tell
end tell
" 2>/dev/null
}

# Dismiss any presented sheet/alert by tapping outside or pressing Escape
# Usage: sim_dismiss
sim_dismiss() {
    sim_key escape
}

echo "sim-interact.sh loaded. Functions: sim_tap, sim_long_press, sim_swipe, sim_type, sim_key, sim_dismiss"
