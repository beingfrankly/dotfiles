# ~/.config/zsh/.zprofile - Login shell configuration

# Prefer user-installed tools, including bd, after macOS login PATH setup.
_local_bin="$HOME/.local/bin"
path=(${path:#$_local_bin})
path=("$_local_bin" $path)
unset _local_bin
export PATH

# Added by Obsidian
[[ -d "/Applications/Obsidian.app/Contents/MacOS" ]] && export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
