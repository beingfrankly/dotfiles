# Nordic Theme

A comprehensive colorscheme based on [Nordic.nvim](https://github.com/AlexvZyl/nordic.nvim) for consistent theming across all your tools.

## 🚀 Quick Start

**See [INTEGRATION.md](./INTEGRATION.md) for complete setup instructions!**

### Quick Setup

1. **Ghostty**: Already configured! Theme installed at `~/.config/ghostty/themes/nordic`
2. **Neovim**: Already configured! Just restart Neovim
3. **Shell tools**: Add to `~/.zshrc`:
   ```bash
   source ~/.config/theme/zsh.sh
   eval "$(oh-my-posh init zsh --config ~/.config/theme/oh-my-posh.json)"
   ```
4. **Git**: Run `git config --global include.path ~/.config/theme/delta.gitconfig`
5. **lazygit/lazydocker**: Symlink the config files (see INTEGRATION.md)

## Color Palette

The full color palette is defined in `colors.yaml` and `colors.sh`.

### Main Colors (Darker Background)
- **Background**: `#1E222A` (black1) - Darker for better contrast
- **Background Dark**: `#191D24` (black0) - Darkest variant
- **Foreground**: `#D8DEE9` (white1)
- **Selection**: `#3B4252` (gray2)
- **Cursor**: `#D8DEE9` (white1)

### ANSI Terminal Colors
Standard 16-color ANSI palette using Nordic colors.

## Architecture

### Single Source of Truth
All **shell-based** configurations (`eza.sh`, `fzf.sh`, `zsh.sh`, `sketchybar.sh`) source `colors.sh` and use its variables. This means:
- **To change colors globally**: Just edit `colors.sh`
- **Shell tools automatically update**: eza, fzf, zsh highlighting, and Sketchybar all reference the same colors

### Tool-Specific Configs
Tools that don't support shell sourcing need manual color updates:
- **Ghostty** - Proper theme file at `~/.config/ghostty/themes/nordic`
- **Neovim** - Lua colorscheme at `~/.config/nvim/colors/nordic.lua`
- **oh-my-posh** - JSON theme
- **delta** - Git config
- **lazygit/lazydocker** - YAML configs

These tools use their native configuration formats and load themes differently than shell scripts.

## Supported Tools

This theme includes configurations for:
- **Ghostty** - Terminal emulator
- **Neovim** - Text editor
- **eza** - Modern ls replacement
- **fzf** - Fuzzy finder
- **delta** - Git diff viewer
- **lazygit** - Git TUI
- **lazydocker** - Docker TUI
- **Sketchybar** - macOS status bar
- **zsh** - Shell colors
- **oh-my-posh** - Prompt theme

## Usage

Each tool has its own configuration file in this directory. See **[INTEGRATION.md](./INTEGRATION.md)** for detailed integration instructions.

### Shell Integration

To use these colors in shell scripts:
```bash
source ~/.config/theme/colors.sh
echo "$NORDIC_BLUE1"  # Use the color variables
```

## Color Reference

| Color | Hex | Usage |
|-------|-----|-------|
| Black 0 | `#191D24` | Darkest background |
| Black 1 | `#1E222A` | Dark background |
| Black 2 | `#222630` | Dark background |
| Gray 0 | `#242933` | Background dark |
| Gray 1 | `#2E3440` | Main background |
| Gray 2 | `#3B4252` | Dark foreground |
| Gray 3 | `#434C5E` | Selection |
| Gray 4 | `#4C566A` | Bright black |
| Gray 5 | `#60728A` | Comments |
| White 0 | `#BBC3D4` | Normal text |
| White 1 | `#D8DEE9` | Foreground |
| White 2 | `#E5E9F0` | Bright foreground |
| White 3 | `#ECEFF4` | Brightest foreground |
| Blue 0 | `#5E81AC` | Blue (dim) |
| Blue 1 | `#81A1C1` | Blue (normal) |
| Blue 2 | `#88C0D0` | Blue (bright) |
| Cyan | `#8FBCBB` | Cyan |
| Red | `#BF616A` | Red/Error |
| Orange | `#D08770` | Orange/Warning |
| Yellow | `#EBCB8B` | Yellow |
| Green | `#A3BE8C` | Green/Success |
| Magenta | `#B48EAD` | Magenta |
