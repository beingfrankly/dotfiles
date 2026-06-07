# CLAUDE.md - Dotfiles Configuration

This file provides guidance to Claude Code when working with this dotfiles repository.

**Note**: Universal CLI tool preferences and file editing guidelines are now in `~/.claude/CLAUDE.md` (global configuration).

## Quick Reference

**Before making ANY changes:**
1. Run health check: `~/.config/scripts/health-check.sh`
2. Read files before editing them (see global CLAUDE.md for guidelines)
3. Check "Dangerous Operations Warning" section before modifying critical files

**After making changes:**
1. Reload services: `aerospace reload-config` or `brew services restart sketchybar`
2. Verify no errors in logs
3. Test in new terminal/window before committing

**Key Architecture Points:**
- AeroSpace → SketchyBar integration via `exec-on-workspace-change` hook
- Zsh loads in order: functions → exports → aliases → plugins
- Neovim uses Kickstart (not a distribution)
- SSH agent setup prevents 50+ process leak (DO NOT MODIFY)
- Karabiner remaps Cmd+Tab for workspace switching (REQUIRED)

## Repository Overview

This is a macOS development environment configuration repository managed with **GNU Stow** at `~/.dotfiles`. Each subdirectory is a stow "package" that mirrors the target hierarchy relative to `$HOME`. Running `stow <pkg>` from `~/.dotfiles` creates symlinks into `~/.config/` (or `~/` for `.zshenv`).

## Configuration Structure

```
~/.dotfiles/
├── .stow-local-ignore       # Exclude docs/Makefile from stowing
├── .gitignore                # Standard blacklist gitignore
├── Makefile                  # install/uninstall/restow commands
├── CLAUDE.md, README.md, CLI_TOOLS.md
│
├── zsh/                      # Special: .zshenv stows to ~
│   ├── .zshenv               # → ~/.zshenv
│   └── .config/zsh/          # → ~/.config/zsh/*
│
├── nvim/.config/nvim/        # → ~/.config/nvim/*
├── ghostty/.config/ghostty/  # → ~/.config/ghostty/*
├── git/.config/git/          # → ~/.config/git/{config,ignore}
├── aerospace/.config/aerospace/
├── karabiner/.config/karabiner/
├── atuin/.config/atuin/
├── bat/.config/bat/
├── lazygit/.config/lazygit/
├── lazydocker/.config/lazydocker/
├── starship/.config/starship.toml
├── oh-my-posh/.config/oh-my-posh/
├── eza/.config/eza/
├── theme/.config/theme/      # Unified theme files
├── scripts/.config/scripts/
└── claude/.claude/CLAUDE.md  # → ~/.claude/CLAUDE.md
```

### No-Folding Packages
These packages use `--no-folding` (individual file symlinks, not directory symlinks) because the target dirs contain mixed tracked/generated files:
- **git**: `config-hfs` (work secrets) alongside tracked `config`
- **karabiner**: daemon writes `automatic_backups/` alongside `karabiner.json`
- **nvim**: lazy.nvim generates `lazy-lock.json`, `plugin/`, `spell/`
- **zsh**: secrets, history, cache, plugins live alongside tracked files
- **claude**: `~/.claude/` has history, plans, session data — only `CLAUDE.md` is ours

## Common Operations

### Service Management

```bash
# Restart SketchyBar (after config changes)
brew services restart sketchybar

# Reload AeroSpace configuration
aerospace reload-config

# Restart Ghostty
# No command needed - just quit and reopen the app
```

### Configuration Editing

When editing configuration files, always reload the relevant service afterward:

- **AeroSpace** (aerospace/aerospace.toml): `aerospace reload-config`
- **SketchyBar** (sketchybar/): `brew services restart sketchybar`
- **Ghostty** (ghostty/config): No reload needed, changes apply to new windows
- **Neovim** (nvim/): Restart Neovim or `:source $MYVIMRC`
- **Zsh** (zsh/.zshrc): `source ~/.config/zsh/.zshrc` or restart terminal

### Testing Changes

After making configuration changes:
1. Test in a new terminal window/tab first
2. Verify no errors in system logs: `log show --predicate 'process == "SketchyBar"' --last 5m`
3. For AeroSpace, check behavior with test window before committing

### Pre-flight Validation Commands

Before making changes, verify the environment is correctly set up:

```bash
# Verify all modern CLI tools are installed
command -v eza && command -v bat && command -v fd && command -v rg && command -v dust && command -v duf && echo "✓ All CLI tools present"

# Check if critical services are running
brew services list | rg sketchybar
pgrep -x "AeroSpace" > /dev/null && echo "✓ AeroSpace running"

# Verify Karabiner is active (required for workspace switching)
pgrep -x "karabiner" > /dev/null && echo "✓ Karabiner-Elements running"

# Validate zsh configuration syntax
zsh -n ~/.config/zsh/.zshrc && echo "✓ Zsh config valid"

# Check AeroSpace config syntax
aerospace list-workspaces --all > /dev/null && echo "✓ AeroSpace config valid"

# Verify Neovim can start
nvim --headless +checkhealth +qall 2>&1 | rg -q "ERROR" && echo "⚠ Neovim health check has errors" || echo "✓ Neovim healthy"
```

## Modern CLI Tools in This Environment

This environment uses modern CLI alternatives (see global `~/.claude/CLAUDE.md` for the complete reference). These tools are aliased in `zsh/zsh-aliases`:

- `eza` → `l`, `ll`, `la` aliases for file listing
- `bat` → `cat`, `catt` aliases for viewing files
- `fd` → `find` alias for file search
- `rg` → `grep` alias for content search
- `dust` → `du` alias for disk usage
- `duf` → `df` alias for disk free space

When executing bash commands in this project, use the modern tool names directly (e.g., `eza`, `bat`, `fd`, `rg`).

## Dangerous Operations Warning

**⚠️ CRITICAL: The following sections should RARELY be modified. Always ask the user before making changes:**

1. **SSH Agent Setup** (`zsh/.zshrc:188-194`)
   - Prevents 50+ process leak
   - Breaking this causes severe performance degradation
   - User specifically configured this to fix a critical issue

2. **Karabiner Cmd+Tab Remapping** (`karabiner/karabiner.json`)
   - Required for AeroSpace workspace switching
   - Disabling breaks the entire workspace system
   - macOS protects Cmd+Tab, this is the workaround

3. **AeroSpace Workspace Change Hook** (`aerospace/aerospace.toml:20-22`)
   - Core integration between AeroSpace and SketchyBar
   - Breaking this disconnects workspace indicators
   - Modifying the command format can break SketchyBar plugins

4. **Zsh Loading Order** (`zsh/.zshrc:117-129`)
   - Carefully ordered for performance and functionality
   - Plugins must load in specific order (syntax-highlighting before autosuggestions)
   - Changing order can cause conflicts or failures

5. **Work Secrets File** (`zsh/secrets-hfs.sh`)
   - Never commit this file
   - Never echo or display its contents
   - Never reference specific values in tracked files

## Architecture & Integration Points

### AeroSpace ↔ SketchyBar Integration

The workspace system is tightly integrated:

- **AeroSpace** (`aerospace/aerospace.toml:20-22`): Executes `exec-on-workspace-change` hook that triggers SketchyBar
- **SketchyBar** (`sketchybar/items/spaces.sh`): Subscribes to `aerospace_workspace_change` event
- **Plugin** (`sketchybar/plugins/aerospace.sh`): Updates visual state of workspace indicators

When adding new workspaces:
1. Add keybinding in `aerospace/aerospace.toml` (lines 117-138)
2. SketchyBar will automatically discover it via `aerospace list-workspaces --all`
3. Update workspace assignments in `aerospace/aerospace.toml` (lines 182-264) if needed

### Zsh Configuration Loading Order

The shell configuration is modular (`zsh/.zshrc`):

1. **Line 117-129**: Load order is: `zsh-functions` → `zsh-exports` → `zsh-aliases`
2. **Line 131-145**: Plugins load after base config (syntax-highlighting must load before autosuggestions)
3. **Line 147-185**: External tool integrations (zoxide, fzf, atuin, etc.)
4. **Line 188-194**: SSH agent setup (prevents 50+ process leak)

When modifying shell configuration:
- Add environment variables to `zsh-exports`
- Add command aliases to `zsh-aliases`
- Add shell functions to `zsh-functions`
- Add plugin configurations to `.zshrc` after line 131

### Neovim (Kickstart) Structure

This is a **Kickstart.nvim** configuration (`nvim/init.lua`):

- **Line 90-91**: Leader key is `<space>`
- **Line 97-106**: Configuration is modular (options, keymaps, lazy-bootstrap, lazy-plugins)
- **Line 112-120**: LSP servers enabled: lua_ls, vtsls, astro, html, jsonls
- **Line 122-124**: Custom scopes plugin for monorepo navigation

Kickstart is **not a distribution** - it's a starting point. When making changes:
- Read the entire file top-to-bottom to understand the configuration
- Use `:help` and `<space>sh` to search documentation
- Configuration is in `lua/` directory, organized by concern

### Theme System

A unified Nordic theme is applied across all tools:

- **Colors**: Defined in `~/.config/theme/colors.sh` and `~/.config/theme/oh-my-posh.json`
- **Ghostty**: Uses `~/.config/theme/ghostty` (line 19)
- **Zsh**: Syntax highlighting colors (`.zshrc:213-227`), autosuggestions (`.zshrc:230`)
- **FZF**: Colors set in `zsh-exports:17-21` and `~/.config/theme/fzf.sh`
- **EZA**: Colors in `~/.config/theme/eza.sh`

When changing theme, update all theme files in `~/.config/theme/` directory.

## Common Workflows

### Adding a New Workspace

To add a new workspace (e.g., workspace "M" for Music):

1. **Add keybindings** in `aerospace/aerospace.toml` under `[mode.main.binding]`:
   ```toml
   alt-m = 'workspace M'
   alt-shift-m = 'move-node-to-workspace M'
   ```

2. **Test the workspace**:
   ```bash
   aerospace reload-config
   aerospace workspace M  # Should switch to new workspace
   ```

3. **Verify SketchyBar integration**:
   ```bash
   brew services restart sketchybar
   # The new workspace "M" should appear in the status bar
   ```

4. **(Optional) Add app assignments** in `aerospace/aerospace.toml`:
   ```toml
   [[on-window-detected]]
   if.app-id = 'com.apple.Music'
   run = "move-node-to-workspace M"
   ```

### Adding an Application to Workspace Assignment

To automatically assign an app to a specific workspace:

1. **Find the app bundle ID**:
   ```bash
   # Open the app first, then run:
   aerospace list-windows --all | rg -i "app-name"
   # Or use:
   osascript -e 'id of app "AppName"'
   ```

2. **Add to `aerospace/aerospace.toml`** (around line 182-264):
   ```toml
   [[on-window-detected]]
   if.app-id = 'com.company.appname'
   run = "move-node-to-workspace X"
   ```

3. **Reload and test**:
   ```bash
   aerospace reload-config
   # Close and reopen the app - it should appear in the assigned workspace
   ```

### Adding a New SketchyBar Item

To add a new status bar item (e.g., network indicator):

1. **Create item definition** in `sketchybar/items/network.sh`:
   ```bash
   #!/bin/bash

   sketchybar --add item network right \
              --set network \
              update_freq=5 \
              icon="" \
              script="$PLUGIN_DIR/network.sh"
   ```

2. **Create plugin script** in `sketchybar/plugins/network.sh`:
   ```bash
   #!/bin/bash

   # Your logic here
   STATUS="connected"

   sketchybar --set $NAME label="$STATUS"
   ```

3. **Make plugin executable**:
   ```bash
   chmod +x sketchybar/plugins/network.sh
   ```

4. **Source in main config** (`sketchybar/sketchybarrc`):
   ```bash
   source $ITEM_DIR/network.sh
   ```

5. **Reload SketchyBar**:
   ```bash
   brew services restart sketchybar
   ```

### Adding a Neovim Plugin

To add a new plugin using lazy.nvim:

1. **Create or edit** the plugin file in `nvim/lua/lazy-plugins.lua` (or check existing structure)

2. **Add plugin configuration**:
   ```lua
   {
     'author/plugin-name',
     config = function()
       require('plugin-name').setup({
         -- your config here
       })
     end,
   }
   ```

3. **Restart Neovim** - lazy.nvim will auto-install on startup

4. **Or manually sync**:
   - Open Neovim
   - Run `:Lazy sync`

5. **Check for errors**:
   ```vim
   :checkhealth
   :Lazy log
   ```

### Adding Zsh Aliases or Functions

To add new shell aliases or functions:

1. **For aliases** - Edit `zsh/zsh-aliases`:
   ```bash
   alias myalias='command with args'
   ```

2. **For functions** - Edit `zsh/zsh-functions`:
   ```bash
   myfunction() {
     # function body
   }
   ```

3. **For environment variables** - Edit `zsh/zsh-exports`:
   ```bash
   export MY_VAR="value"
   ```

4. **Test the changes**:
   ```bash
   source ~/.config/zsh/.zshrc
   # Or restart terminal
   ```

### Updating the Theme

To change the color theme across all tools:

1. **Update theme files** in `~/.config/theme/`:
   - `colors.sh` - Base color definitions
   - `oh-my-posh.json` - Prompt colors
   - `ghostty` - Terminal colors
   - `eza.sh` - File listing colors
   - `fzf.sh` - Fuzzy finder colors

2. **Update tool-specific configs**:
   - **Zsh**: `.zshrc:213-231` - Syntax highlighting colors
   - **Neovim**: `nvim/colors/` - Color scheme
   - **SketchyBar**: `sketchybar/colors.sh` - Status bar colors

3. **Reload everything**:
   ```bash
   source ~/.config/zsh/.zshrc
   brew services restart sketchybar
   # Restart Ghostty and Neovim
   ```

## Additional Modern Tools

Beyond the standard replacements (see global CLAUDE.md), this environment includes:

- **zoxide (`z`)**: Smart directory jumping based on frecency
- **fzf**: Fuzzy finder for command history and file search
- **atuin**: Enhanced shell history with sync capabilities

See `CLI_TOOLS.md` for detailed documentation on all tools.

## Workspace Organization

Workspaces are letter/number-based with automatic app assignments:

- **1, 2, 3**: General purpose
- **O**: Obsidian (notes)
- **D**: DBeaver (database)
- **S**: Slack, Teams (communication)
- **B**: Arc, Chrome (browsers)
- **C**: Cursor, VSCode, IntelliJ (code editors)
- **T**: Ghostty (terminal)
- **N**: General workspace

App-to-workspace assignments are defined in `aerospace/aerospace.toml:182-264` using `[[on-window-detected]]` blocks.

## Performance Optimizations

### SSH Agent Management

**Critical**: The SSH agent setup (`zsh/.zshrc:188-194`) prevents a process leak that previously created 50+ ssh-agent processes.

Do not modify this section without understanding the impact. The current implementation:
1. Checks if ssh-agent is already running for the user
2. Only starts a new agent if none exists
3. Reuses the existing agent across all shells

### Shell Startup Speed

- **Completion cache** (`.zshrc:32-38`): Only regenerates once per day
- **Oh My Posh** (`.zshrc:163-165`): Configured with `fetch_status: false` in theme JSON for instant prompts in git repos
- **Git config** (`git/config`): Uses `untracked cache` for faster status checks

### Zsh Profiling

To identify slow shell startup:
1. Uncomment line 8 in `.zshrc`: `zmodload zsh/zprof`
2. Uncomment line 261 in `.zshrc`: `zprof`
3. Restart shell and review output

## Keybinding Philosophy

Three-layer split management system:

1. **AeroSpace (Alt+...)**: App/window-level tiling
2. **Ghostty (Cmd+...)**: Terminal process splits
3. **Neovim (Ctrl+...)**: File/buffer splits

This layering prevents conflicts and provides intuitive, progressive refinement of workspace organization.

### Karabiner Remapping

**Critical**: `Cmd+Tab` is remapped to `Ctrl+Tab` via Karabiner-Elements to enable AeroSpace workspace switching (macOS protects Cmd+Tab from being overridden directly).

The remapping is in `karabiner/karabiner.json`. Do not disable Karabiner or workspace switching will break.

## Git & Stow Workflow

**Note**: See global `~/.claude/CLAUDE.md` for universal git best practices.

This repository uses **GNU Stow** for symlink management. The `.gitignore` uses a standard blacklist approach (secrets, generated files, `.DS_Store`).

### Stow Commands
```bash
cd ~/.dotfiles
make install     # Stow all packages
make uninstall   # Unstow all packages
make restow      # Re-stow all (after adding files)
make <pkg>       # Stow a single package (e.g., make nvim)
```

### Adding a New Config Package
1. Create the stow package structure: `mkdir -p <pkg>/.config/<pkg>/`
2. Add config files inside the package
3. If the target dir has mixed tracked/generated content, add it to the `NO_FOLD` list in `Makefile`
4. Add any generated/secret files to `.gitignore`
5. Run `stow <pkg>` (or `stow --no-folding <pkg>` for no-fold packages)
6. Commit and push

## Work-Specific Configuration

Work secrets are loaded from `zsh/secrets-hfs.sh` (`.gitignore` excludes this file). This file contains:
- API keys
- Company-specific environment variables
- Private configurations

Never commit this file or reference its contents in tracked files.

## Docker Configuration

- **Active**: Docker Desktop (not Colima)
- **Testcontainers**: Configured in `.zshrc:173-175`
- **Socket**: `/var/run/docker.sock`

If switching to Colima, uncomment line 173 in `.zshrc`.

## Version Management

- **ASDF** (`.zshrc:167-258`): Manages language versions
- **Auto-install**: Automatically runs `asdf install` when entering directories with `.tool-versions`

When adding new language versions, use:
```bash
asdf plugin add <language>
asdf install <language> <version>
asdf local <language> <version>  # Creates .tool-versions
```

## Environment Health Check

Run these commands to verify the entire environment is functioning correctly:

```bash
#!/bin/bash
# Quick health check for the entire environment

echo "=== Environment Health Check ==="
echo ""

# CLI Tools
echo "CLI Tools:"
for tool in eza bat fd rg dust duf fzf zoxide; do
  command -v $tool > /dev/null && echo "  ✓ $tool" || echo "  ✗ $tool (missing)"
done
echo ""

# Core Services
echo "Core Services:"
pgrep -x "AeroSpace" > /dev/null && echo "  ✓ AeroSpace running" || echo "  ✗ AeroSpace not running"
brew services list | rg -q "sketchybar.*started" && echo "  ✓ SketchyBar running" || echo "  ✗ SketchyBar not running"
pgrep -x "karabiner" > /dev/null && echo "  ✓ Karabiner running" || echo "  ✗ Karabiner not running"
echo ""

# Configuration Syntax
echo "Configuration Syntax:"
zsh -n ~/.config/zsh/.zshrc 2>&1 && echo "  ✓ Zsh config valid" || echo "  ✗ Zsh config has errors"
aerospace list-workspaces --all > /dev/null 2>&1 && echo "  ✓ AeroSpace config valid" || echo "  ✗ AeroSpace config invalid"
echo ""

# Workspace Integration
echo "Workspace Integration:"
aerospace list-workspaces --all | wc -l | xargs -I {} echo "  ✓ {} workspaces configured"
echo ""

# SSH Agent
echo "SSH Agent:"
pgrep -u "$USER" ssh-agent > /dev/null && echo "  ✓ SSH agent running" || echo "  ✗ SSH agent not running"
echo ""

# Version Managers
echo "Version Managers:"
command -v asdf > /dev/null && echo "  ✓ ASDF installed" || echo "  ✗ ASDF not installed"
command -v pnpm > /dev/null && echo "  ✓ PNPM installed" || echo "  ✗ PNPM not installed"
echo ""

echo "=== Health Check Complete ==="
```

Save this as `~/.config/scripts/health-check.sh` and run `chmod +x ~/.config/scripts/health-check.sh`

## Dependency Versions

Current versions of critical tools (as of last update):

```bash
# Check versions
aerospace --version          # AeroSpace tiling window manager
sketchybar --version         # Status bar
nvim --version | head -n1    # Neovim editor
eza --version                # Modern ls (0.23.4)
bat --version                # Modern cat (0.25.0)
fd --version                 # Modern find (10.3.0)
rg --version                 # Ripgrep (14.1.1)
atuin --version              # Shell history (18.8.0)
oh-my-posh --version         # Prompt theme
zsh --version                # Zsh shell
git --version                # Git
brew --version               # Homebrew

# Check ASDF plugins and versions
asdf plugin list
asdf current
```

**Note**: When troubleshooting, check if version mismatches might be causing issues. This environment was designed with the versions listed above.

## Common Issues

### SketchyBar workspaces not showing
Run: `brew services restart sketchybar`

### Cmd+Tab not switching workspaces
1. Check Karabiner-Elements has Input Monitoring permissions
2. Verify Karabiner is running: `ps aux | grep karabiner`
3. Check remap rule is enabled in Karabiner UI

### Slow prompt in git repositories
1. Verify `fetch_status: false` in `~/.config/theme/oh-my-posh.json`
2. Check git config: `git config --get core.untrackedCache` (should be `true`)

### Neovim LSP not working
1. Check LSP is enabled in `nvim/init.lua:112-120`
2. Run `:checkhealth` in Neovim
3. Verify language server is installed: `which <server-name>`

## Additional Resources

- **Global Configuration**: `~/.claude/CLAUDE.md` - Universal guidelines for all projects
- **AeroSpace**: https://nikitabobko.github.io/AeroSpace/guide
- **SketchyBar**: https://felixkratz.github.io/SketchyBar/
- **Ghostty**: https://ghostty.org/docs
- **Kickstart.nvim**: https://github.com/nvim-lua/kickstart.nvim
- **Obsidian vault**: `~/Sync/Obsidian/Second Brain`

## Auto-Restow Git Hook

`.githooks/post-merge` runs `make restow` after every merge so newly tracked dotfiles get
symlinked automatically. `core.hooksPath=.githooks` (re-asserted in `make install`).
**Beads shares this path** — `.githooks/` holds all 5 beads hooks chaining to
`bd hooks run <name>`; preserve the `BEGIN/END BEADS INTEGRATION` blocks when editing any hook.

For Neovim config testing (`nvim-test`), see `references/nvim.md`.
