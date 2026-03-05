# Modern CLI Tools Reference

This is your complete guide to the modern CLI tools installed on your system.

## 📦 Installed Tools

| Old Tool | Modern Replacement | Version | Description |
|----------|-------------------|---------|-------------|
| `ls` | **eza** | 0.23.4 | File listing with icons & colors |
| `cat` | **bat** | 0.25.0 | Syntax highlighting & git integration |
| `find` | **fd** | 10.3.0 | Fast, user-friendly file finder |
| `grep` | **ripgrep (rg)** | 14.1.1 | Lightning-fast search |
| `du` | **dust** | 1.2.3 | Intuitive disk usage |
| `df` | **duf** | latest | Beautiful disk usage overview |
| `cd` | **zoxide** | - | Smarter directory jumping |
| Shell history | **atuin** | 18.8.0 | Supercharged shell history |

---

## 🎨 eza - Modern ls

### Basic Commands
```bash
ls              # Simple listing with icons
l               # Long format, all files
ll              # Long format (no hidden)
la              # Long format with all files
```

### Tree Views
```bash
lt              # Tree (2 levels)
lt3             # Tree (3 levels)
lta             # Full tree
```

### Git Integration
```bash
lg              # Show git status
lgg             # Show git repos
```

### Smart Sorting
```bash
lm              # Sort by modified time
lz              # Sort by size
lx              # Sort by extension
```

### Features
- 🎨 Beautiful colors
- 📁 File type icons
- 🌲 Tree view built-in
- 🔄 Git status integration
- ⚡ Blazing fast

---

## 🦇 bat - Better cat

### Basic Usage
```bash
cat file.txt                    # Syntax highlighting
catt file.txt                   # Plain output
catd file1.txt file2.txt        # Show diff
```

### Advanced
```bash
bat --language=rust file.txt    # Force syntax
bat -A file.txt                 # Show all chars
bat --line-range 10:20 file.txt # Specific lines
bat --diff file1.txt file2.txt  # Side-by-side diff
```

### Features
- 🎨 Syntax highlighting for 200+ languages
- 📊 Line numbers
- 🔄 Git integration (shows changes)
- 📄 Automatic paging
- 🎭 Multiple themes

### Themes
Current: `Monokai Extended`

View all: `bat --list-themes`

---

## 🔍 fd - Better find

### Basic Usage
```bash
fd pattern                      # Find files/dirs
fd -e js                       # Find by extension
fd -t f pattern                # Files only
fd -t d pattern                # Directories only
fd -H pattern                  # Include hidden
fd -I pattern                  # Include ignored (.gitignore)
```

### Advanced
```bash
fd '^test.*\.js$'              # Regex search
fd -x bat {}                   # Execute command on results
fd -e md -x wc -l              # Count lines in markdown
fd . /path                     # Search in specific path
```

### Features
- ⚡ 5-10x faster than `find`
- 🎨 Colorful output
- 🔍 Smart case (lowercase = insensitive)
- 🚫 Respects .gitignore by default
- 📝 Simpler syntax

---

## 🚀 ripgrep (rg) - Better grep

### Basic Usage
```bash
rg pattern                      # Search in all files
rg -i pattern                  # Case insensitive
rg -w word                     # Match whole word
rg -v pattern                  # Invert match
rg -l pattern                  # Only filenames
```

### Advanced
```bash
rg -t js pattern               # Search only JS files
rg -T js pattern               # Exclude JS files
rg -g '*.tsx' pattern          # Glob pattern
rg -A 3 -B 3 pattern          # Show context (3 lines)
rg --hidden pattern            # Include hidden files
rg --no-ignore pattern         # Include ignored files
```

### Features
- ⚡ Fastest search tool
- 🎨 Colored output
- 🚫 Respects .gitignore
- 🔍 Smart case by default
- 📝 Supports regex
- 🌐 Multi-threaded

---

## 💾 dust - Better du

### Basic Usage
```bash
dust                           # Current directory
dust /path                     # Specific path
dust -d 3                      # Max depth 3
dust -r                        # Reverse sort (smallest first)
dust -n 20                     # Show top 20
```

### Features
- 📊 Visual bar charts
- 🎨 Colorful output
- 🌲 Tree view
- 📉 Sorted by size
- ⚡ Fast

---

## 💿 duf - Better df

### Basic Usage
```bash
duf                            # All mounted filesystems
duf /path                      # Specific filesystem
duf --only local              # Only local disks
duf --hide-mp /boot           # Hide mount point
```

### Features
- 📊 Beautiful tables
- 🎨 Color-coded usage
- 📈 Usage bars
- 🔍 Smart filtering
- 💻 Cross-platform

---

## 🚀 Powerful Combined Commands

### Interactive File Preview
```bash
preview                        # Find & preview files with fzf
```
Uses: `fd` + `fzf` + `bat`

### Search in Files
```bash
search                         # Search text & preview
```
Uses: `rg` + `fzf` + `bat`

### Interactive Directory Jump
```bash
cdi                           # Choose directory with preview
```
Uses: `fd` + `fzf` + `eza`

### Git Diff Preview
```bash
gdiff                         # Preview git changes
```
Uses: `git` + `fzf` + `delta`

---

## ⚡ Performance Comparison

| Operation | Old Tool | Time | New Tool | Time | Speedup |
|-----------|----------|------|----------|------|---------|
| Find files | `find` | 2.5s | `fd` | 0.3s | **8x** |
| Search text | `grep` | 3.2s | `rg` | 0.2s | **16x** |
| List files | `ls` | 0.1s | `eza` | 0.08s | **1.25x** |
| Show file | `cat` | instant | `bat` | instant | Same + features |

---

## 🎯 Pro Tips

### 1. Use with FZF
All these tools integrate beautifully with fzf:
```bash
fd | fzf                       # Find & select file
rg . | fzf                     # Search & select result
```

### 2. Combine Tools
```bash
fd -e js | rg 'TODO'          # Find TODOs in JS files
bat $(fd -e md | fzf)         # Preview selected markdown
```

### 3. Use .ignore files
Create `.ignore` files (like `.gitignore`) to exclude patterns from `fd` and `rg`.

### 4. Shell Integration
- `eza` respects `LS_COLORS`
- `bat` uses your git config theme
- `fd` and `rg` respect `.gitignore`

---

## 🔧 Configuration Files

| Tool | Config Location |
|------|----------------|
| eza | None needed (uses env vars) |
| bat | `~/.config/bat/config` |
| fd | None (uses CLI flags) |
| rg | None (uses CLI flags) |
| dust | None needed |
| duf | None needed |

---

## 📚 Learn More

- [eza GitHub](https://github.com/eza-community/eza)
- [bat GitHub](https://github.com/sharkdp/bat)
- [fd GitHub](https://github.com/sharkdp/fd)
- [ripgrep GitHub](https://github.com/BurntSushi/ripgrep)
- [dust GitHub](https://github.com/bootandy/dust)
- [duf GitHub](https://github.com/muesli/duf)

---

**Last Updated**: 2025-10-11
