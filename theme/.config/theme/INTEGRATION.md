# Nordic Theme Integration Guide

This guide will help you integrate the Nordic colorscheme across all your tools.

## Quick Start

All theme files are located in `~/.config/theme/`. Each tool has its own configuration file with instructions.

## Tool-by-Tool Setup

### 1. Ghostty (Terminal)

**Already configured!** The Nordic theme has been installed to `~/.config/ghostty/themes/nordic` and is active in your config.

The theme is loaded with:
```
theme = nordic
```

This follows Ghostty's official theme format. The theme file is located at:
- `~/.config/ghostty/themes/nordic`

To switch back to another theme, change `theme = nordic` to another theme name in your Ghostty config.

### 2. Neovim

**Already configured!** The Nordic colorscheme has been:
- Created at `~/.config/nvim/colors/nordic.lua`
- Set as your active theme in `~/.config/nvim/lua/kickstart/plugins/theme.lua`

Restart Neovim to see the changes.

### 3. eza (ls replacement)

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# Source eza/ls colors
source ~/.config/theme/eza.sh
```

### 4. fzf (Fuzzy Finder)

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# Source fzf colors
source ~/.config/theme/fzf.sh
```

### 5. delta (Git Diff Viewer)

Add to your `~/.gitconfig`:

```gitconfig
[include]
    path = ~/.config/theme/delta.gitconfig
```

Or run:
```bash
git config --global include.path ~/.config/theme/delta.gitconfig
```

### 6. lazygit

**Option A: Copy to config location**
```bash
# macOS
cp ~/.config/theme/lazygit.yml ~/Library/Application\ Support/lazygit/config.yml

# Linux
cp ~/.config/theme/lazygit.yml ~/.config/lazygit/config.yml
```

**Option B: Symlink (recommended)**
```bash
# macOS
ln -s ~/.config/theme/lazygit.yml ~/Library/Application\ Support/lazygit/config.yml

# Linux
ln -s ~/.config/theme/lazygit.yml ~/.config/lazygit/config.yml
```

### 7. lazydocker

**Option A: Copy to config location**
```bash
# macOS
cp ~/.config/theme/lazydocker.yml ~/Library/Application\ Support/lazydocker/config.yml

# Linux
cp ~/.config/theme/lazydocker.yml ~/.config/lazydocker/config.yml
```

**Option B: Symlink (recommended)**
```bash
# macOS
ln -s ~/.config/theme/lazydocker.yml ~/Library/Application\ Support/lazydocker/config.yml

# Linux
ln -s ~/.config/theme/lazydocker.yml ~/.config/lazydocker/config.yml
```

### 8. Sketchybar

**For shell-based config:**

Add to your `~/.config/sketchybar/sketchybarrc`:

```bash
# Source Nordic colors
source ~/.config/theme/sketchybar.sh

# Apply default colors
eval "sketchybar $NORDIC_SKETCHYBAR_DEFAULTS"

# Use colors in items
sketchybar --add item my_item left \
  --set my_item icon.color=$NORDIC_BLUE \
                label.color=$NORDIC_FG \
                background.color=$NORDIC_ITEM_BG
```

**For Lua-based config:**

In your Sketchybar Lua config:

```lua
local colors = require("theme.sketchybar")

-- Use colors
sbar.bar({
  color = colors.bar_bg,
  border_color = colors.border,
})

-- Use state presets
item:set(colors.states.active)
```

### 9. zsh

Add to your `~/.zshrc`:

```bash
# Source Nordic theme for zsh
# This includes LS_COLORS, FZF colors, syntax highlighting, and completion colors
source ~/.config/theme/zsh.sh
```

**Note:** The zsh theme includes:
- LS_COLORS (for file listings)
- FZF colors
- zsh-syntax-highlighting colors (if installed)
- zsh-autosuggestions colors (if installed)
- Completion menu colors
- Man page colors

### 10. oh-my-posh

**Option 1: Use directly**
```bash
# Add to your ~/.zshrc
eval "$(oh-my-posh init zsh --config ~/.config/theme/oh-my-posh.json)"
```

**Option 2: Copy to oh-my-posh themes directory**
```bash
cp ~/.config/theme/oh-my-posh.json ~/.poshthemes/nordic.json
eval "$(oh-my-posh init zsh --config ~/.poshthemes/nordic.json)"
```

## Complete .zshrc Integration

Here's a complete example of what to add to your `~/.zshrc`:

```bash
# ============================================
# Nordic Theme Integration
# ============================================

# Source Nordic colors for shell
source ~/.config/theme/colors.sh

# Zsh colors (includes eza/ls, fzf, syntax highlighting)
source ~/.config/theme/zsh.sh

# oh-my-posh prompt
eval "$(oh-my-posh init zsh --config ~/.config/theme/oh-my-posh.json)"

# ============================================
```

## Customization

### Modifying Colors

To modify colors across all tools:

1. Edit `~/.config/theme/colors.yaml` or `~/.config/theme/colors.sh`
2. Update the specific tool config files with your new colors
3. Reload your shell or restart the application

### Tool-Specific Customization

Each tool's config file is standalone and can be customized independently:

- `ghostty` - Terminal colors
- `nvim/colors/nordic.lua` - Neovim highlight groups
- `eza.sh` - File type colors
- `fzf.sh` - Fuzzy finder UI
- `delta.gitconfig` - Git diff colors
- `lazygit.yml` - Git TUI colors
- `lazydocker.yml` - Docker TUI colors
- `sketchybar.sh` / `sketchybar.lua` - Status bar colors
- `zsh.sh` - Shell syntax and completion colors
- `oh-my-posh.json` - Prompt theme

## Verification

After setup, verify each tool:

```bash
# Test eza colors
eza -la --color=always

# Test fzf colors
echo "test" | fzf

# Test git diff (delta)
git diff

# Test lazygit
lazygit

# Test lazydocker
lazydocker

# Restart Neovim to see new theme
nvim

# Restart Ghostty to see new colors
```

## Troubleshooting

### Colors not showing

1. Ensure your terminal supports 24-bit true color
2. Check that `$TERM` is set correctly (e.g., `xterm-256color`)
3. Verify you've sourced the theme files in your shell config
4. Restart your terminal/shell after making changes

### Neovim theme not loading

1. Check that the colorscheme file exists: `~/.config/nvim/colors/nordic.lua`
2. Verify theme.lua is configured correctly
3. Restart Neovim
4. Check for errors: `:messages` in Neovim

### Shell colors not working

1. Make sure you've sourced the theme files after modifying `.zshrc`
2. Reload your shell: `source ~/.zshrc`
3. Check that the theme files are executable: `chmod +x ~/.config/theme/*.sh`

## Additional Resources

- [Nordic.nvim](https://github.com/AlexvZyl/nordic.nvim) - Original theme inspiration
- [Nord Theme](https://www.nordtheme.com/) - Base color palette
- Theme documentation: `~/.config/theme/README.md`

## Color Palette Reference

Quick reference of Nordic colors:

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| Gray 1 | `#2E3440` | `46, 52, 64` | Background |
| White 1 | `#D8DEE9` | `216, 222, 233` | Foreground |
| Blue 1 | `#81A1C1` | `129, 161, 193` | Primary accent |
| Blue 2 | `#88C0D0` | `136, 192, 208` | Secondary accent |
| Green | `#A3BE8C` | `163, 190, 140` | Success |
| Yellow | `#EBCB8B` | `235, 203, 139` | Warning |
| Red | `#BF616A` | `191, 97, 106` | Error |
| Orange | `#D08770` | `208, 135, 112` | Info |
| Magenta | `#B48EAD` | `180, 142, 173` | Special |
| Cyan | `#8FBCBB` | `143, 188, 187` | Highlight |

---

Enjoy your Nordic-themed setup! 🎨
