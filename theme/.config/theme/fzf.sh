#!/usr/bin/env bash
# Sonokai Andromeda theme for fzf
# Source this file in your shell config: source ~/.config/theme/fzf.sh

# Source base colors
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"

# FZF color scheme using Sonokai Andromeda colors
# Format: element:fg:bg:attribute
export FZF_DEFAULT_OPTS="
  --color=fg:${SONOKAI_FOREGROUND},bg:${SONOKAI_BACKGROUND},hl:${SONOKAI_BLUE_BASE}
  --color=fg+:${SONOKAI_FOREGROUND_BRIGHT},bg+:${SONOKAI_SELECTION},hl+:${SONOKAI_BLUE_BRIGHT}
  --color=info:${SONOKAI_YELLOW_BASE},prompt:${SONOKAI_GREEN_BASE},pointer:${SONOKAI_RED_BASE}
  --color=marker:${SONOKAI_PURPLE_BASE},spinner:${SONOKAI_ORANGE_BASE},header:${SONOKAI_CYAN_BASE}
  --color=border:${SONOKAI_GRAY2},label:${SONOKAI_FOREGROUND},query:${SONOKAI_FOREGROUND}
  --color=gutter:${SONOKAI_BACKGROUND}
  --border='rounded'
  --prompt='❯ '
  --pointer='▶'
  --marker='✓'
  --layout=reverse
  --info=inline
"

# Color mappings:
# fg: Normal text (foreground)
# bg: Background (black)
# hl: Highlighted text (blue)
# fg+: Selected text (foreground bright)
# bg+: Selected background (selection gray)
# hl+: Highlighted selected text (bright blue)
# info: Info line (yellow)
# prompt: Prompt (green)
# pointer: Pointer (red)
# marker: Multi-select marker (purple)
# spinner: Loading spinner (orange)
# header: Header (cyan)
# border: Border (gray)
