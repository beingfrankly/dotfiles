# Neovim

## Testing config before merging (nvim-test)

`nvim-test [-s|--shared] [worktree-path]` (defined in `zsh/.config/zsh/zsh-functions`)
launches Neovim against `<worktree>/nvim/.config/nvim` with isolated XDG dirs, so the
live `~/.config/nvim` is never touched.

- **default (fresh):** plugins reinstall from scratch — honest full validation
- **`-s` / `--shared`:** reuses live `XDG_DATA_HOME` for fast iteration

Gotcha: run `bd` from the repo root — the asdf golang shim breaks `bd` in `nvim/.config/nvim`.
