#!/usr/bin/env bash
# Sonokai Andromeda theme colors for Sketchybar
# Source this file in your sketchybarrc: source ~/.config/theme/sketchybar.sh

# Source base colors
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"

# Convert hex colors to Sketchybar ARGB format (0xAARRGGBB)
# Usage: hex_to_sketchybar "#RRGGBB" -> "0xffRRGGBB"
hex_to_sketchybar() {
  echo "0xff${1:1}" | tr '[:upper:]' '[:lower:]'
}

# Background colors
export SONOKAI_BAR_BG=$(hex_to_sketchybar "$SONOKAI_BACKGROUND")
export SONOKAI_BAR_BG_DARK=$(hex_to_sketchybar "$SONOKAI_BACKGROUND_DARK")
export SONOKAI_ITEM_BG=$(hex_to_sketchybar "$SONOKAI_BACKGROUND_UI")
export SONOKAI_POPUP_BG=$(hex_to_sketchybar "$SONOKAI_BACKGROUND_UI")

# Foreground colors
export SONOKAI_FG=$(hex_to_sketchybar "$SONOKAI_FOREGROUND")
export SONOKAI_FG_BRIGHT=$(hex_to_sketchybar "$SONOKAI_FOREGROUND_BRIGHT")
export SONOKAI_FG_DIM=$(hex_to_sketchybar "$SONOKAI_WHITE0")

# Accent colors
export SONOKAI_BLUE=$(hex_to_sketchybar "$SONOKAI_BLUE_BASE")
export SONOKAI_BLUE_BRIGHT=$(hex_to_sketchybar "$SONOKAI_BLUE_BRIGHT")
export SONOKAI_CYAN=$(hex_to_sketchybar "$SONOKAI_CYAN_BASE")
export SONOKAI_GREEN=$(hex_to_sketchybar "$SONOKAI_GREEN_BASE")
export SONOKAI_YELLOW=$(hex_to_sketchybar "$SONOKAI_YELLOW_BASE")
export SONOKAI_ORANGE=$(hex_to_sketchybar "$SONOKAI_ORANGE_BASE")
export SONOKAI_RED=$(hex_to_sketchybar "$SONOKAI_RED_BASE")
export SONOKAI_PURPLE=$(hex_to_sketchybar "$SONOKAI_PURPLE_BASE")

# UI colors
export SONOKAI_BORDER=$(hex_to_sketchybar "$SONOKAI_SELECTION")
export SONOKAI_SELECTION_BG=$(hex_to_sketchybar "$SONOKAI_SELECTION")
export SONOKAI_COMMENT=$(hex_to_sketchybar "$SONOKAI_COMMENT")

# Common Sketchybar color settings
export SONOKAI_SKETCHYBAR_DEFAULTS="
  --bar color=$SONOKAI_BAR_BG \
  --bar border_color=$SONOKAI_BORDER \
  --default icon.color=$SONOKAI_FG \
  --default label.color=$SONOKAI_FG \
  --default background.color=$SONOKAI_ITEM_BG \
  --default popup.background.color=$SONOKAI_POPUP_BG \
  --default popup.border_color=$SONOKAI_BORDER
"

# Example color functions for items
sonokai_item_active() {
  sketchybar --set "$1" \
    icon.color="$SONOKAI_FG_BRIGHT" \
    label.color="$SONOKAI_FG_BRIGHT" \
    background.color="$SONOKAI_BLUE"
}

sonokai_item_inactive() {
  sketchybar --set "$1" \
    icon.color="$SONOKAI_FG_DIM" \
    label.color="$SONOKAI_FG_DIM" \
    background.color="$SONOKAI_ITEM_BG"
}

sonokai_item_warning() {
  sketchybar --set "$1" \
    icon.color="$SONOKAI_YELLOW" \
    label.color="$SONOKAI_YELLOW"
}

sonokai_item_error() {
  sketchybar --set "$1" \
    icon.color="$SONOKAI_RED" \
    label.color="$SONOKAI_RED"
}

sonokai_item_success() {
  sketchybar --set "$1" \
    icon.color="$SONOKAI_GREEN" \
    label.color="$SONOKAI_GREEN"
}

# Usage example in sketchybarrc:
# source ~/.config/theme/sketchybar.sh
# sketchybar $SONOKAI_SKETCHYBAR_DEFAULTS
# sketchybar --add item my_item left \
#   --set my_item icon.color=$SONOKAI_BLUE \
#                 label.color=$SONOKAI_FG \
#                 background.color=$SONOKAI_ITEM_BG
