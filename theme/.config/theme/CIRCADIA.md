# Circadia Warm Parchment

Active tools: Ghostty, Neovim, Herdr, Starship, fzf, eza, bat, lazygit and delta.
Lazydocker uses terminal ANSI colors and follows Ghostty without overrides.

Source: https://github.com/tanmaymanojgandhi/circadia

The Neovim modules in `nvim/.config/nvim/lua/circadia` are vendored unchanged from the upstream port with its MIT license. The local `colors/circadia-light.lua` exposes the standard colorscheme command. Ghostty translates upstream Kitty light colors; other tool configurations adapt the same semantic palette, with a distinct red for errors and pale diff backgrounds.

Reload Ghostty using its Reload Configuration action. Restart Neovim or run `:colorscheme circadia-light`. Open a new shell for fzf exports and restart running terminal tools. Herdr supports `herdr server reload-config`; after bat theme updates run `bat cache --build`.
