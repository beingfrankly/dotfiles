-- Oshen.nvim: colorscheme
-- https://github.com/54L1M/Oshen.nvim
-- Ships two variants: 'oshen-night' (dark) and 'oshen-day' (light).
-- Both react to `:set background=...` and re-apply live.
-- Loaded first by pack.lua so later modules can read the palette.

local oshen = require('kickstart.util').try_require('oshen', 'Oshen.nvim')
if not oshen then return end

oshen.setup({
  transparent = false,
})
vim.cmd.colorscheme 'oshen-night'
