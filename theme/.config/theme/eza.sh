#!/usr/bin/env bash
# Nordic theme for eza (modern ls replacement)
# Source this file in your shell config: source ~/.config/theme/eza.sh
# Or add to .zshrc: export EZA_COLORS="$NORDIC_EZA_COLORS"

# Source base colors
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"

# Convert hex color to RGB ANSI format for LS_COLORS
# Usage: hex_to_rgb "#RRGGBB" -> "38;2;R;G;B"
hex_to_rgb() {
  local hex="${1#\#}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  echo "38;2;${r};${g};${b}"
}

# Build LS_COLORS using Nordic palette
export NORDIC_EZA_COLORS="\
di=$(hex_to_rgb "$NORDIC_BLUE1"):\
ln=$(hex_to_rgb "$NORDIC_BLUE2"):\
ex=$(hex_to_rgb "$NORDIC_GREEN_BASE"):\
fi=$(hex_to_rgb "$NORDIC_FOREGROUND"):\
*.jpg=$(hex_to_rgb "$NORDIC_MAGENTA_BASE"):\
*.png=$(hex_to_rgb "$NORDIC_MAGENTA_BASE"):\
*.gif=$(hex_to_rgb "$NORDIC_MAGENTA_BASE"):\
*.svg=$(hex_to_rgb "$NORDIC_MAGENTA_BASE"):\
*.mp3=$(hex_to_rgb "$NORDIC_MAGENTA_BASE"):\
*.mp4=$(hex_to_rgb "$NORDIC_MAGENTA_BASE"):\
*.zip=$(hex_to_rgb "$NORDIC_ORANGE_BASE"):\
*.tar=$(hex_to_rgb "$NORDIC_ORANGE_BASE"):\
*.gz=$(hex_to_rgb "$NORDIC_ORANGE_BASE"):\
*.md=$(hex_to_rgb "$NORDIC_YELLOW_BASE"):\
*.txt=$(hex_to_rgb "$NORDIC_FOREGROUND"):\
*.pdf=$(hex_to_rgb "$NORDIC_RED_BASE"):\
*.doc=$(hex_to_rgb "$NORDIC_BLUE1"):\
*.rs=$(hex_to_rgb "$NORDIC_ORANGE_BASE"):\
*.js=$(hex_to_rgb "$NORDIC_YELLOW_BASE"):\
*.ts=$(hex_to_rgb "$NORDIC_BLUE1"):\
*.py=$(hex_to_rgb "$NORDIC_BLUE1"):\
*.go=$(hex_to_rgb "$NORDIC_BLUE1"):\
*.rb=$(hex_to_rgb "$NORDIC_RED_BASE"):\
*.java=$(hex_to_rgb "$NORDIC_ORANGE_BASE"):\
*.cpp=$(hex_to_rgb "$NORDIC_BLUE1"):\
*.c=$(hex_to_rgb "$NORDIC_BLUE1"):\
*.h=$(hex_to_rgb "$NORDIC_CYAN_BASE"):\
*.json=$(hex_to_rgb "$NORDIC_YELLOW_BASE"):\
*.yaml=$(hex_to_rgb "$NORDIC_YELLOW_BASE"):\
*.yml=$(hex_to_rgb "$NORDIC_YELLOW_BASE"):\
*.toml=$(hex_to_rgb "$NORDIC_YELLOW_BASE"):\
*.xml=$(hex_to_rgb "$NORDIC_ORANGE_BASE"):\
*.html=$(hex_to_rgb "$NORDIC_ORANGE_BASE"):\
*.css=$(hex_to_rgb "$NORDIC_BLUE1"):\
*.sh=$(hex_to_rgb "$NORDIC_GREEN_BASE"):\
*.bash=$(hex_to_rgb "$NORDIC_GREEN_BASE"):\
*.zsh=$(hex_to_rgb "$NORDIC_GREEN_BASE"):\
*.fish=$(hex_to_rgb "$NORDIC_GREEN_BASE"):\
or=$(hex_to_rgb "$NORDIC_RED_BASE"):\
mi=$(hex_to_rgb "$NORDIC_RED_BASE"):\
so=$(hex_to_rgb "$NORDIC_MAGENTA_BASE"):\
bd=$(hex_to_rgb "$NORDIC_ORANGE_BASE"):\
cd=$(hex_to_rgb "$NORDIC_ORANGE_BASE"):\
pi=$(hex_to_rgb "$NORDIC_BLUE1"):\
*.git=$(hex_to_rgb "$NORDIC_GRAY4")"

# Also set LS_COLORS for compatibility
export LS_COLORS="$NORDIC_EZA_COLORS"

# Color mappings reference:
# di = directory (blue1)
# ln = symbolic link (blue2)
# ex = executable (green)
# fi = regular file (foreground)
# or = orphaned symlink (red)
# mi = missing file (red)
# Images/media = magenta
# Archives = orange
# Documents = yellow or blue
# Source code = various colors by language
