#!/usr/bin/env zsh
# ~/.config/zsh/.zshrc - Interactive shell configuration

# ===== Performance Monitoring (optional - comment out if not needed) =====
# zmodload zsh/zprof  # Commented out - enable when profiling

# Skip insecure directory check (for Homebrew-installed completions)
DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_COMPFIX="true"

# ===== Zinit Plugin Manager =====
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33}Installing Zinit...%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"

# Load Zinit annexes (plugins for plugins)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

# ===== Completions Setup =====
# Add custom completions directory to fpath
fpath=($ZDOTDIR/completions $fpath)

# Enable completions with security check only once per day
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Replay cached completions
zinit cdreplay -q

# ===== Zsh Options =====
# History settings
setopt APPEND_HISTORY          # Append to history file
setopt SHARE_HISTORY           # Share history between sessions
setopt HIST_IGNORE_ALL_DUPS    # Remove older duplicate entries
setopt HIST_REDUCE_BLANKS      # Remove superfluous blanks
setopt HIST_VERIFY             # Show command with history expansion before running
setopt EXTENDED_HISTORY        # Save timestamp and duration
setopt HIST_IGNORE_SPACE       # Don't save commands starting with space

# History file location (XDG compliant)
HISTFILE="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/history"
HISTSIZE=50000
SAVEHIST=50000

# Ensure history directory exists
[[ ! -d "${HISTFILE:h}" ]] && mkdir -p "${HISTFILE:h}"

# Directory navigation
setopt AUTO_CD                 # Auto cd when typing directory name
setopt AUTO_PUSHD              # Push old directory onto stack
setopt PUSHD_IGNORE_DUPS       # Don't push duplicates
setopt PUSHD_SILENT            # Don't print directory stack

# Completion options
setopt COMPLETE_IN_WORD        # Complete from both ends
setopt ALWAYS_TO_END           # Move cursor to end after completion
setopt AUTO_MENU               # Show completion menu on tab
setopt AUTO_LIST               # List choices on ambiguous completion
setopt MENU_COMPLETE           # Insert first match immediately

# Other options
setopt EXTENDED_GLOB           # Extended globbing
setopt INTERACTIVE_COMMENTS    # Allow comments in interactive mode
setopt NO_BEEP                 # No beeping
setopt PROMPT_SUBST            # Enable prompt substitution

# Disable Ctrl-S freeze
stty stop undef

# Disable paste highlighting
zle_highlight=('paste:none')

# ===== Completion Styles =====
zstyle ':completion:*' menu select                                    # Select completions with arrow keys
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'            # Case insensitive completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"              # Colorful completions
zstyle ':completion:*' group-name ''                                  # Group completions by category
zstyle ':completion:*:descriptions' format '%F{#81A1C1}%B-- %d --%b%f'     # Format group descriptions (Nordic blue)
zstyle ':completion:*:warnings' format '%F{#BF616A}-- no matches --%f'     # No matches message (Nordic red)
zstyle ':completion:*:messages' format '%F{#A3BE8C}-- %d --%f'             # Messages (Nordic green)
zstyle ':completion:*:corrections' format '%F{#EBCB8B}-- %d (errors: %e) --%f'  # Corrections (Nordic yellow)
zstyle ':completion:*' use-cache on                                   # Use completion cache
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"  # Cache location
zstyle ':completion:*:*:*:*:*' menu select                           # Always use menu
zstyle ':completion:*' rehash true                                    # Rehash for new commands

# Better completion for kill command
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always

# Docker completion
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

# Include hidden files in completions
_comp_options+=(globdots)

# ===== Key Bindings =====
# Use emacs mode (or change to bindkey -v for vim mode)
bindkey -e

# Better history search with arrow keys
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search     # Up arrow
bindkey "^[[B" down-line-or-beginning-search   # Down arrow

# ===== Load Local Configuration =====
# Load exports
if [[ -f "$ZDOTDIR/zsh-exports" ]]; then
    source "$ZDOTDIR/zsh-exports"
fi

# Load aliases
if [[ -f "$ZDOTDIR/zsh-aliases" ]]; then
    source "$ZDOTDIR/zsh-aliases"
fi

# Load shell functions
if [[ -f "$ZDOTDIR/zsh-functions" ]]; then
    source "$ZDOTDIR/zsh-functions"
fi

# ===== Plugins via Zinit =====
# Syntax highlighting (critical - load immediately, must be before autosuggestions)
zinit light zsh-users/zsh-syntax-highlighting

# Autosuggestions (can load after first prompt for faster startup)
zinit wait lucid light-mode for \
    zsh-users/zsh-autosuggestions
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
export ZSH_AUTOSUGGEST_USE_ASYNC=1

# Completions (with blockf to prevent conflicts, can load after first prompt)
zinit ice blockf wait lucid light-mode
zinit light zsh-users/zsh-completions

# Auto-close brackets and quotes (can load after first prompt)
zinit wait lucid light-mode for \
    hlissner/zsh-autopair

# ===== External Tool Integrations =====
# Zoxide (better cd) - optimized for speed
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# FZF (fuzzy finder)
if command -v fzf &> /dev/null; then
    eval "$(fzf --zsh)"
fi

# Ghostty shell integration
if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
    source "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration"
fi

# Starship prompt (fast, cross-shell prompt)
if command -v starship &> /dev/null; then
    # Enable performance profiling for starship (can disable later)
    export STARSHIP_LOG=error  # Only log errors, not debug info
    
    # Initialize starship
    eval "$(starship init zsh)"
fi


# Direnv (per-directory environment variables)
if command -v direnv &> /dev/null; then
    eval "$(direnv hook zsh)"
fi

# Atuin (better shell history)
if command -v atuin &> /dev/null; then
    eval "$(atuin init zsh)"
fi

# ===== SSH Agent =====
# Better SSH agent management
if [[ -z "$SSH_AUTH_SOCK" ]]; then
    eval "$(ssh-agent -s)" > /dev/null
    # Add common SSH keys if they exist
    [[ -f ~/.ssh/id_ed25519 ]] && ssh-add ~/.ssh/id_ed25519 2>/dev/null
    [[ -f ~/.ssh/id_rsa ]] && ssh-add ~/.ssh/id_rsa 2>/dev/null
fi

# ===== Colors =====
autoload -Uz colors && colors

# Enable ls colors
if [[ "$OSTYPE" == darwin* ]]; then
    export CLICOLOR=1
    export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd
fi

# ===== PNPM Setup =====
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac


# asdf auto-install missing versions
# asdf_auto_install() {
#   if [ -f .tool-versions ] || [ -f .asdfrc ]; then
#     asdf install
#   fi
# }

# # Auto-install when changing directories
# autoload -U add-zsh-hook
# add-zsh-hook chpwd asdf_auto_install
#
# # Run on shell startup for current directory
# asdf_auto_install

# ===== Performance Monitoring (optional) =====
# Enable prompt timing profiling (uncomment to enable)
# This will show how long each command takes to execute
# zmodload zsh/zprof  # Uncomment to enable profiling

# Performance hook: measure prompt rendering time
# Uncomment to enable timing measurements
# _prompt_perf_start() {
#     [[ -n "$ZSH_PROF" ]] && typeset -gF _prompt_start_time=$EPOCHREALTIME
# }
# _prompt_perf_end() {
#     [[ -n "$ZSH_PROF" && -n "$_prompt_start_time" ]] && \
#         print -P "%F{yellow}Prompt took $(( (EPOCHREALTIME - _prompt_start_time) * 1000 ))ms%f" >&2
# }
# add-zsh-hook precmd _prompt_perf_end
# add-zsh-hook preexec _prompt_perf_start
#
# ASDF (version manager)
if command -v brew >/dev/null 2>&1 && [[ -f "$(brew --prefix asdf)/libexec/asdf.sh" ]]; then
    . "$(brew --prefix asdf)/libexec/asdf.sh"
fi

# Keep local installers ahead of asdf/Homebrew after all PATH integrations run.
_local_bin="$HOME/.local/bin"
path=(${path:#$_local_bin})
path=("$_local_bin" $path)
unset _local_bin
export PATH

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
# Added by go-hfs setup --mcp
export PATH="$PATH:/Users/Frank.vanEldijk/code/hfs/*/mcp"
# Added by go-hfs setup --mcp
export PATH="$PATH:/Users/Frank.vanEldijk/code/hfs/II-7050-company-type-fix/mcp"
