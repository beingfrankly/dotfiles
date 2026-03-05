# Nordic Theme Setup Guide

A comprehensive guide to understanding and maintaining your Nordic-themed development environment.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [File Structure](#file-structure)
- [Making Changes](#making-changes)
- [Tool-Specific Details](#tool-specific-details)
- [Contrast Adjustments](#contrast-adjustments)
- [Troubleshooting](#troubleshooting)

---

## Overview

This setup provides a consistent Nordic color theme across all your development tools using a centralized configuration approach. The theme is based on [Nordic.nvim](https://github.com/AlexvZyl/nordic.nvim) with a custom darker background variant for increased contrast.

### Current Color Values (10% Increased Contrast)

| Purpose | Color | Notes |
|---------|-------|-------|
| Background | `#1B1F26` | Main background (darker) |
| Background Dark | `#171A20` | Darkest variant |
| Foreground | `#DCE1EB` | Main text (lighter) |
| Foreground Bright | `#EEF1F5` | Brightest text |
| Selection | `#353B4A` | Selection/highlight bg (darker) |
| Cursor | `#DCE1EB` | Cursor color |

---

## Architecture

### Two-Tier System

The theme uses a **two-tier approach**:

#### 1. Shell-Based Tools (Dynamic)
These tools can source bash scripts and automatically pick up changes from `colors.sh`:

```
colors.sh (source of truth)
    ↓
├─→ eza.sh (converts to LS_COLORS format)
├─→ fzf.sh (uses hex colors directly)
├─→ zsh.sh (syntax highlighting & completion)
└─→ sketchybar.sh (converts to ARGB format)
```

**Benefit**: Edit `colors.sh` once, all shell tools update automatically.

#### 2. Native Format Tools (Static)
These tools use their own configuration formats and need manual updates:

```
colors.sh (reference only)
    ↓ (manual sync)
├─→ ghostty (Ghostty theme format)
├─→ neovim (Lua colorscheme)
├─→ oh-my-posh (JSON)
├─→ delta (Git config)
├─→ lazygit (YAML)
├─→ lazydocker (YAML)
└─→ sketchybar.lua (Lua config)
```

**Reason**: These tools run in environments without access to bash variables (e.g., Neovim's Lua VM, Ghostty's config parser).

---

## File Structure

```
~/.config/theme/
├── colors.sh              # Central color definitions (bash exports)
├── colors.yaml            # Central color definitions (YAML format)
├── README.md              # Quick reference guide
├── INTEGRATION.md         # Detailed integration instructions
├── SETUP.md               # This file
│
├── eza.sh                 # LS_COLORS for file listings (sources colors.sh)
├── fzf.sh                 # Fuzzy finder colors (sources colors.sh)
├── zsh.sh                 # Shell syntax highlighting (sources colors.sh)
├── sketchybar.sh          # Status bar colors - bash (sources colors.sh)
├── sketchybar.lua         # Status bar colors - Lua (hardcoded)
│
├── ghostty                # Reference file (see actual theme below)
├── oh-my-posh.json        # Prompt theme
├── delta.gitconfig        # Git diff viewer colors
├── lazygit.yml            # Git TUI colors
└── lazydocker.yml         # Docker TUI colors

~/.config/ghostty/themes/
└── nordic                 # Actual Ghostty theme file

~/.config/nvim/colors/
└── nordic.lua             # Neovim colorscheme
```

---

## Making Changes

### Changing Colors for Shell Tools

**Edit once, update everywhere:**

1. Edit `~/.config/theme/colors.sh`
2. Change the exported color values
3. Reload your shell: `source ~/.config/zsh/.zshrc`

**Example**: To change the background color:
```bash
# In ~/.config/theme/colors.sh
export NORDIC_BACKGROUND='#1B1F26'  # Change this hex value
```

This automatically updates:
- eza (file listings)
- fzf (fuzzy finder)
- zsh (syntax highlighting)
- sketchybar.sh (if using shell version)

### Changing Colors for Native Tools

**Must update each tool's config file individually:**

1. **Ghostty**: Edit `~/.config/ghostty/themes/nordic`
   - Format: `background = #1b1f26`
   - Apply: Restart Ghostty

2. **Neovim**: Edit `~/.config/nvim/colors/nordic.lua`
   - Find color definitions in the `colors` table
   - Apply: Restart Neovim or `:colorscheme nordic`

3. **oh-my-posh**: Edit `~/.config/theme/oh-my-posh.json`
   - Update the `palette` section
   - Apply: New shell session

4. **delta**: Edit `~/.config/theme/delta.gitconfig`
   - Update color values throughout
   - Apply: Immediately active

5. **lazygit**: Edit `~/.config/theme/lazygit.yml`
   - Update theme color values
   - Apply: Restart lazygit

6. **lazydocker**: Edit `~/.config/theme/lazydocker.yml`
   - Update theme color values
   - Apply: Restart lazydocker

7. **Sketchybar Lua**: Edit `~/.config/theme/sketchybar.lua`
   - Update `colors` table (ARGB format: `0xAARRGGBB`)
   - Apply: Restart Sketchybar

---

## Tool-Specific Details

### Ghostty

**Location**: `~/.config/ghostty/themes/nordic`

**Format**: Ghostty theme configuration
```
background = #1b1f26
foreground = #dce1eb
palette = 0=#3b4252
```

**Loading**: Your `~/.config/ghostty/config` loads it with:
```
theme = nordic
```

**Why separate?**: Ghostty themes must be in the official format and can't source shell scripts.

### Neovim

**Location**: `~/.config/nvim/colors/nordic.lua`

**Format**: Pure Lua colorscheme
```lua
local colors = {
  bg = '#1B1F26',
  fg = '#DCE1EB',
  -- ...
}
```

**Loading**: Your `~/.config/nvim/lua/kickstart/plugins/theme.lua` loads it with:
```lua
vim.cmd.colorscheme 'nordic'
```

**Why separate?**: Neovim's Lua environment can't access bash environment variables.

### Shell Tools (eza, fzf, zsh)

**Locations**:
- `~/.config/theme/eza.sh`
- `~/.config/theme/fzf.sh`
- `~/.config/theme/zsh.sh`

**Format**: Each sources `colors.sh` and converts colors to the tool's format
```bash
source "$SCRIPT_DIR/colors.sh"
export FZF_DEFAULT_OPTS="--color=fg:${NORDIC_FOREGROUND}..."
```

**Loading**: Your `~/.config/zsh/.zshrc` sources them:
```bash
source ~/.config/theme/colors.sh
source ~/.config/theme/eza.sh
source ~/.config/theme/fzf.sh
```

**Benefit**: Change `colors.sh` → all tools update automatically.

### oh-my-posh

**Location**: `~/.config/theme/oh-my-posh.json`

**Format**: JSON theme configuration
```json
{
  "palette": {
    "background": "#1B1F26",
    "foreground": "#DCE1EB"
  }
}
```

**Loading**: Your `~/.config/zsh/.zshrc` initializes it:
```bash
eval "$(oh-my-posh init zsh --config ~/.config/theme/oh-my-posh.json)"
```

### Git Tools (delta, lazygit, lazydocker)

**Locations**:
- `~/.config/theme/delta.gitconfig`
- `~/Library/Application Support/lazygit/config.yml` (symlink)
- `~/Library/Application Support/lazydocker/config.yml` (symlink)

**Format**: Native config formats (git config, YAML)

**Loading**:
- delta: Git includes it globally
- lazygit/lazydocker: Symlinked to theme folder

**Benefit of symlinks**: Edit in `~/.config/theme/`, changes apply immediately.

### Sketchybar

**Locations**:
- `~/.config/theme/sketchybar.sh` (bash version - sources colors.sh)
- `~/.config/theme/sketchybar.lua` (Lua version - hardcoded)

**Why two versions?**: Sketchybar supports both bash and Lua configs.

**Bash version** (dynamic):
```bash
source ~/.config/theme/colors.sh
export NORDIC_BAR_BG=$(hex_to_sketchybar "$NORDIC_BACKGROUND")
```

**Lua version** (static):
```lua
local colors = {
  bar_bg = 0xff1b1f26,
}
```

---

## Contrast Adjustments

### Current State: 10% Increased Contrast

The theme has been adjusted for better readability:

**What Changed**:
- Dark colors made 10% darker
- Light colors made 10% lighter
- Selection backgrounds darkened for better visibility

**Before** (Original Nordic):
```
Background:  #2E3440
Foreground:  #D8DEE9
Selection:   #434C5E
```

**After** (10% Increased):
```
Background:  #1B1F26  ← darker
Foreground:  #DCE1EB  ← lighter
Selection:   #353B4A  ← darker
```

### Further Adjustments

To increase/decrease contrast:

1. **Calculate new values**: Use a color calculator or adjust RGB values
2. **Update `colors.sh`**: Change the semantic color exports
3. **Update native tools**: Manually sync the new values to each tool's config
4. **Test**: Reload/restart each tool to verify appearance

**Example workflow**:
```bash
# 1. Edit colors.sh
vim ~/.config/theme/colors.sh

# 2. Test shell tools immediately
source ~/.config/zsh/.zshrc

# 3. Update native tools one by one
vim ~/.config/ghostty/themes/nordic
vim ~/.config/nvim/colors/nordic.lua
# ... etc

# 4. Restart applications to see changes
```

---

## Troubleshooting

### Colors Not Updating

**Shell tools (eza, fzf, zsh)**:
- Solution: Reload shell with `source ~/.config/zsh/.zshrc`
- Check: Verify `colors.sh` is being sourced

**Native tools (Ghostty, Neovim, etc.)**:
- Solution: Restart the application
- Check: Verify you edited the correct config file
- Common issue: Editing reference files instead of actual config files

### Inconsistent Colors Between Tools

**Likely cause**: Forgot to update a native tool's config

**Solution**:
1. Check `colors.sh` for the correct values
2. Search for the old color value in all config files
3. Update any files that still have old values

**Example**:
```bash
# Find files with old background color
cd ~/.config/theme
grep -r "#1E222A" .

# Also check
grep -r "#1e222a" ~/.config/ghostty/themes/
grep -r "#1E222A" ~/.config/nvim/colors/
```

### Ghostty Theme Not Loading

**Check**:
1. Theme file exists: `ls ~/.config/ghostty/themes/nordic`
2. Config loads theme: `grep "theme = nordic" ~/.config/ghostty/config`
3. No syntax errors in theme file

**Fix**:
```bash
# Verify theme file
cat ~/.config/ghostty/themes/nordic

# Restart Ghostty
# (Close all windows and reopen)
```

### Neovim Colors Wrong

**Check**:
1. Colorscheme file exists: `ls ~/.config/nvim/colors/nordic.lua`
2. Theme is loaded: Check `~/.config/nvim/lua/kickstart/plugins/theme.lua`
3. No Lua syntax errors

**Debug in Neovim**:
```vim
:colorscheme      " Check current colorscheme
:messages         " Check for errors
:colorscheme nordic  " Reload manually
```

### Shell Highlighting Not Working

**Requirements**:
- `zsh-syntax-highlighting` plugin installed
- `zsh-autosuggestions` plugin installed (for suggestions)

**Check your zsh plugin manager** (zinit, oh-my-zsh, etc.) has loaded these plugins before sourcing the theme.

---

## Additional Resources

- **README.md**: Quick reference and color palette
- **INTEGRATION.md**: Step-by-step integration guide for each tool
- **Nordic.nvim**: https://github.com/AlexvZyl/nordic.nvim (original inspiration)
- **Ghostty Themes**: https://ghostty.org/docs/features/theme
- **Nord Theme**: https://www.nordtheme.com/ (base palette)

---

## Quick Reference Commands

```bash
# Reload shell colors
source ~/.config/zsh/.zshrc

# Edit main color definitions
vim ~/.config/theme/colors.sh

# Edit Ghostty theme
vim ~/.config/ghostty/themes/nordic

# Edit Neovim theme
vim ~/.config/nvim/colors/nordic.lua

# View current colors
cat ~/.config/theme/colors.yaml

# Check which files reference a color
cd ~/.config/theme
grep -r "#1B1F26" .
```

---

**Last Updated**: After 10% contrast increase
**Theme Version**: Nordic (Custom Dark Variant)
**Base**: https://github.com/AlexvZyl/nordic.nvim
