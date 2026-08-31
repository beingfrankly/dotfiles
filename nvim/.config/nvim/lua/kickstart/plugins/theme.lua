-- luna.nvim: colorscheme
-- https://github.com/WTFox/luna.nvim
-- Near-black background with warm and cool syntax accents.
-- `accent` blends the syntax accents toward grey over the range 0..1.
-- Loaded first by pack.lua so later modules can read the palette.

local luna = require('kickstart.util').try_require('luna', 'luna.nvim')
if not luna then return end

luna.setup({
  transparent = false,
  accent = 1.0,
  plugins = {
    all = true,
    auto = false,
  },
})
vim.cmd.colorscheme 'luna'
