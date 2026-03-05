# macOS Development Environment Configuration

This repository contains my personal configuration files for a highly optimized macOS development setup using AeroSpace (tiling window manager), Ghostty (terminal), Neovim, and SketchyBar.

## 🛠️ Tech Stack

- **Window Manager**: [AeroSpace](https://github.com/nikitabobko/AeroSpace) - i3-inspired tiling window manager for macOS
- **Status Bar**: [SketchyBar](https://github.com/FelixKratz/SketchyBar) - Highly customizable macOS status bar
- **Terminal**: [Ghostty](https://ghostty.org/) - Fast, native, GPU-accelerated terminal emulator
- **Editor**: [Neovim](https://neovim.io/) - Hyperextensible Vim-based text editor (Kickstart config)
- **Shell**: Zsh with [Oh My Posh](https://ohmyposh.dev/) prompt
- **Key Remapping**: [Karabiner-Elements](https://karabiner-elements.pqrs.org/) - Keyboard customizer

## 📁 Tracked Configurations

```
.config/
├── aerospace/          # Window manager configuration
├── sketchybar/         # Status bar configuration
│   ├── items/         # Bar item definitions
│   └── plugins/       # Event handler scripts
├── ghostty/           # Terminal emulator configuration
├── nvim/              # Neovim configuration (Kickstart-based)
├── zsh/               # Zsh shell configuration
├── oh-my-posh/        # Prompt theme configuration
├── starship.toml      # Alternative prompt (currently unused)
├── karabiner/         # Keyboard remapping configuration
├── lazygit/           # Git TUI configuration
├── lazydocker/        # Docker TUI configuration
└── .gitignore         # This file
```

## 🎯 Key Features

### AeroSpace + SketchyBar Integration
- **Workspace indicators** display all workspaces in the status bar
- **Active workspace highlighting** with visual feedback
- **Click-to-switch** workspace functionality
- **Auto-sync** workspace changes between AeroSpace and SketchyBar

### Three-Layer Split Management
1. **AeroSpace** (App-level) - Different types of applications
2. **Ghostty** (Process-level) - Different terminal processes
3. **Neovim** (File-level) - Multiple files in the same project

### Performance Optimizations
- **Single ssh-agent instance** (fixed 50+ process leak)
- **Fast prompt rendering** with Oh My Posh (instant in git repos)
- **Git optimizations** for large repositories
- **Disabled expensive starship modules**

## ⌨️ Complete Keybinding Reference

### Workspace Management (AeroSpace)
| Keybinding | Action |
|------------|--------|
| `Cmd+Tab` | Toggle between last 2 workspaces |
| `Alt+1/2/3` | Jump to workspace 1/2/3 |
| `Alt+O` | Jump to workspace O (Obsidian) |
| `Alt+D` | Jump to workspace D (Database) |
| `Alt+S` | Jump to workspace S (Slack/Teams) |
| `Alt+B` | Jump to workspace B (Browser) |
| `Alt+C` | Jump to workspace C (Code/Cursor) |
| `Alt+T` | Jump to workspace T (Terminal) |
| `Alt+N` | Jump to workspace N |
| `Alt+Shift+[key]` | Move window to workspace |
| `Alt+H/J/K/L` | Focus window left/down/up/right |
| `Alt+Shift+H/J/K/L` | Move window left/down/up/right |
| `Alt+Shift+F` | Toggle fullscreen |
| `Alt+/` | Toggle layout (tiles/accordion) |
| `Alt+Shift+Tab` | Move workspace to next monitor |
| `Alt+Shift+R` | Enter resize mode |

### Terminal Splits (Ghostty)
| Keybinding | Action |
|------------|--------|
| `Cmd+D` | Split right (vertical) |
| `Cmd+Shift+D` | Split down (horizontal) |
| `Cmd+H/J/K/L` | Navigate splits (vim-style) |
| `Cmd+Shift+H/J/K/L` | Resize splits |
| `Cmd+W` | Close current split/tab |
| `Cmd+Shift+Z` | Zoom/maximize current split |
| `Cmd+Ctrl+F` | Native macOS fullscreen |
| `Cmd+T` | New tab |
| `Cmd+Shift+[` | Previous tab |
| `Cmd+Shift+]` | Next tab |
| `Cmd+1-5` | Jump to tab 1-5 |
| `Cmd+N` | New window |

### File Splits (Neovim)
| Keybinding | Action |
|------------|--------|
| `Ctrl+H/J/K/L` | Navigate splits |
| `Space+\|` | Split window vertically |
| `Space+-` | Split window horizontally |
| `Space+X` | Close current split |
| `Ctrl+Arrow Keys` | Resize splits |
| `Space+=` | Equalize split sizes |

### Code Actions (Neovim)
| Keybinding | Action |
|------------|--------|
| `Space+F` | Format buffer |
| `Space+RN` | Rename symbol |
| `Space+CA` | Code action |
| `GD` | Go to definition |
| `GR` | Go to references |
| `GI` | Go to implementation |

### Search (Neovim)
| Keybinding | Action |
|------------|--------|
| `Space+SF` | Search files in scope |
| `Space+SG` | Search grep in scope |
| `Space+SW` | Search current word |
| `Space+PB` | Pick buffer |
| `Space+PS` | Pick scope/project |

## 🎨 Workspace Organization

### Workspace Assignments
- **1, 2, 3**: General purpose workspaces
- **O**: Obsidian (Notes)
- **D**: DBeaver (Database tools)
- **S**: Slack, Microsoft Teams (Communication)
- **B**: Arc, Chrome (Browsers)
- **C**: Cursor, VSCode, IntelliJ (Code editors)
- **T**: Ghostty (Terminal)
- **N**: General workspace

## 🚀 Performance Notes

### Shell Startup
- **Zsh config**: Modular setup with separate files for exports, aliases, functions
- **SSH Agent**: Reuses existing agent instead of spawning new ones
- **Oh My Posh**: Configured with minimal git status checks for speed
- **Starship**: Available but currently disabled (slower in large git repos)

### Git Performance
- **untracked cache**: Enabled for faster status checks
- **Oh My Posh**: `fetch_status: false` for instant prompts in git repos

## 🔧 System Modifications

### Disabled macOS Shortcuts
These native shortcuts are disabled to avoid conflicts:
- `Cmd+H` - Hide window (disabled)
- `Cmd+M` - Minimize window (disabled)
- `Cmd+Tab` - App switcher (remapped via Karabiner)

### Karabiner-Elements Remapping
- `Cmd+Tab` → `Ctrl+Tab` (for AeroSpace workspace switching)
- `Cmd+Shift+Tab` → `Ctrl+Shift+Tab` (reverse direction)

## 📦 Installation

### Prerequisites
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install applications
brew install --cask aerospace
brew install --cask ghostty
brew install --cask karabiner-elements
brew install sketchybar
brew install neovim
brew install lazygit
brew install lazydocker
brew install oh-my-posh
```

### Setup
```bash
# Clone this repository
git clone <your-repo-url> ~/.config

# Restart services
brew services restart sketchybar
aerospace reload-config

# Restart Ghostty and Karabiner-Elements
# Grant necessary permissions in System Settings → Privacy & Security
```

## 🐛 Troubleshooting

### SketchyBar not showing workspaces
```bash
brew services restart sketchybar
```

### Cmd+Tab not switching workspaces
- Check Karabiner-Elements has Input Monitoring permissions
- Verify the remap rule is enabled in Karabiner-Elements settings

### Slow prompt in git repositories
- Oh My Posh is configured for speed with minimal git checks
- If using starship instead, consider disabling `git_status` module

## 🎓 Resources

- [AeroSpace Documentation](https://nikitabobko.github.io/AeroSpace/guide)
- [SketchyBar Documentation](https://felixkratz.github.io/SketchyBar/)
- [Ghostty Documentation](https://ghostty.org/docs)
- [Kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
- [Karabiner-Elements Documentation](https://karabiner-elements.pqrs.org/docs/)

## 📝 Credits

Configuration inspired by:
- [josean-dev/dev-environment-files](https://github.com/josean-dev/dev-environment-files) - SketchyBar setup
- [nvim-lua/kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) - Neovim configuration
- AeroSpace community configurations

---

**Last Updated**: 2025-10-11
