# ~/.zshenv - Environment variables (sourced first, always)
# This file is sourced by all zsh instances

# Skip insecure directory check (for Homebrew-installed completions)
export ZSH_DISABLE_COMPFIX=true

# XDG Base Directory
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# Zsh config location
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# History configuration
export HISTFILE="$ZDOTDIR/.zhistory"
export HISTSIZE=50000
export SAVEHIST=50000

# Cargo (Rust)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# ASDF version manager
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
