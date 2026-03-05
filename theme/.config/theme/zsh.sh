#!/usr/bin/env bash
# Sonokai Andromeda theme for zsh
# Source this file in your .zshrc: source ~/.config/theme/zsh.sh

# Source base colors
source ~/.config/theme/colors.sh

# LS_COLORS for file listings (used by ls, eza, etc.)
source ~/.config/theme/eza.sh

# FZF colors
source ~/.config/theme/fzf.sh

# Enable color support
autoload -U colors && colors

# ZSH syntax highlighting colors (if using zsh-syntax-highlighting)
# Uses colors from colors.sh sourced above
if [[ -n "${ZSH_HIGHLIGHT_STYLES}" ]]; then
  # Main highlighter
  ZSH_HIGHLIGHT_STYLES[default]="fg=${SONOKAI_FOREGROUND}"
  ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=${SONOKAI_RED_BASE},bold"
  ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=${SONOKAI_BLUE_BASE},bold"
  ZSH_HIGHLIGHT_STYLES[alias]="fg=${SONOKAI_GREEN_BASE}"
  ZSH_HIGHLIGHT_STYLES[suffix-alias]="fg=${SONOKAI_GREEN_BASE}"
  ZSH_HIGHLIGHT_STYLES[builtin]="fg=${SONOKAI_BLUE_BASE}"
  ZSH_HIGHLIGHT_STYLES[function]="fg=${SONOKAI_BLUE_BRIGHT}"
  ZSH_HIGHLIGHT_STYLES[command]="fg=${SONOKAI_GREEN_BASE}"
  ZSH_HIGHLIGHT_STYLES[precommand]="fg=${SONOKAI_GREEN_BASE}"
  ZSH_HIGHLIGHT_STYLES[commandseparator]="fg=${SONOKAI_WHITE0}"
  ZSH_HIGHLIGHT_STYLES[hashed-command]="fg=${SONOKAI_GREEN_BASE}"
  ZSH_HIGHLIGHT_STYLES[path]="fg=${SONOKAI_FOREGROUND}"
  ZSH_HIGHLIGHT_STYLES[path_pathseparator]="fg=${SONOKAI_WHITE0}"
  ZSH_HIGHLIGHT_STYLES[path_prefix]="fg=${SONOKAI_FOREGROUND}"
  ZSH_HIGHLIGHT_STYLES[path_approx]="fg=${SONOKAI_FOREGROUND}"
  ZSH_HIGHLIGHT_STYLES[globbing]="fg=${SONOKAI_YELLOW_BASE}"
  ZSH_HIGHLIGHT_STYLES[history-expansion]="fg=${SONOKAI_BLUE_BRIGHT},bold"
  ZSH_HIGHLIGHT_STYLES[single-hyphen-option]="fg=${SONOKAI_ORANGE_BASE}"
  ZSH_HIGHLIGHT_STYLES[double-hyphen-option]="fg=${SONOKAI_ORANGE_BASE}"
  ZSH_HIGHLIGHT_STYLES[back-quoted-argument]="fg=${SONOKAI_PURPLE_BASE}"
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=${SONOKAI_GREEN_BASE}"
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=${SONOKAI_GREEN_BASE}"
  ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]="fg=${SONOKAI_CYAN_BASE}"
  ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]="fg=${SONOKAI_CYAN_BASE}"
  ZSH_HIGHLIGHT_STYLES[assign]="fg=${SONOKAI_FOREGROUND}"
  ZSH_HIGHLIGHT_STYLES[redirection]="fg=${SONOKAI_ORANGE_BASE}"
  ZSH_HIGHLIGHT_STYLES[comment]="fg=${SONOKAI_COMMENT},italic"
  ZSH_HIGHLIGHT_STYLES[arg0]="fg=${SONOKAI_GREEN_BASE}"

  # Brackets highlighter
  ZSH_HIGHLIGHT_STYLES[bracket-level-1]="fg=${SONOKAI_BLUE_BASE},bold"
  ZSH_HIGHLIGHT_STYLES[bracket-level-2]="fg=${SONOKAI_GREEN_BASE},bold"
  ZSH_HIGHLIGHT_STYLES[bracket-level-3]="fg=${SONOKAI_YELLOW_BASE},bold"
  ZSH_HIGHLIGHT_STYLES[bracket-level-4]="fg=${SONOKAI_ORANGE_BASE},bold"
  ZSH_HIGHLIGHT_STYLES[bracket-error]="fg=${SONOKAI_RED_BASE},bold"

  # Cursor highlighter
  ZSH_HIGHLIGHT_STYLES[cursor]='standout'
fi

# ZSH autosuggestions color (if using zsh-autosuggestions)
if [[ -n "${ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE}" ]]; then
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=${SONOKAI_COMMENT}"
fi

# Completion menu colors
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu select
zstyle ':completion:*:descriptions' format "%F{${SONOKAI_BLUE_BASE}}%B%d%b%f"
zstyle ':completion:*:messages' format "%F{${SONOKAI_GREEN_BASE}}%d%f"
zstyle ':completion:*:warnings' format "%F{${SONOKAI_RED_BASE}}No matches found%f"
zstyle ':completion:*:corrections' format "%F{${SONOKAI_YELLOW_BASE}}%d (errors: %e)%f"

# Man pages colors (using less)
export LESS_TERMCAP_mb=$'\E[01;31m'     # begin blinking - red
export LESS_TERMCAP_md=$'\E[01;34m'     # begin bold - blue
export LESS_TERMCAP_me=$'\E[0m'         # end mode
export LESS_TERMCAP_se=$'\E[0m'         # end standout-mode
export LESS_TERMCAP_so=$'\E[45;37m'     # begin standout-mode - magenta bg
export LESS_TERMCAP_ue=$'\E[0m'         # end underline
export LESS_TERMCAP_us=$'\E[04;36m'     # begin underline - cyan

# Set terminal title colors
case "$TERM" in
  xterm*|rxvt*|alacritty*|ghostty*)
    precmd() {
      print -Pn "\e]0;%n@%m: %~\a"
    }
    ;;
esac

# Color reference:
# All colors sourced from ~/.config/theme/colors.sh
# Blue: SONOKAI_BLUE_BASE / SONOKAI_BLUE_BRIGHT (commands, builtins)
# Green: SONOKAI_GREEN_BASE (strings, success)
# Yellow: SONOKAI_YELLOW_BASE (globs, warnings)
# Red: SONOKAI_RED_BASE (errors, unknown)
# Orange: SONOKAI_ORANGE_BASE (options, redirections)
# Cyan: SONOKAI_CYAN_BASE (special chars)
# Purple: SONOKAI_PURPLE_BASE (back quotes)
# Gray: SONOKAI_COMMENT (comments, suggestions)
# White: SONOKAI_FOREGROUND (default text)
