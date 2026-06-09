-- diffview.nvim: side-by-side diff and merge tool for Git
-- https://github.com/sindrets/diffview.nvim
--
-- Used by atlas.nvim for PR diff rendering (atlas.lua sets diff.open_cmd = 'DiffviewOpen').
-- Also available standalone via :DiffviewOpen, :DiffviewClose, :DiffviewFileHistory.

local diffview = require('kickstart.util').try_require('diffview', 'diffview.nvim')
if not diffview then return end

diffview.setup({})

-- Optional convenience keymap (paired with atlas's <leader>P* cluster)
vim.keymap.set('n', '<leader>Pd', '<cmd>DiffviewOpen<cr>', { desc = 'Diffview: open' })
vim.keymap.set('n', '<leader>PD', '<cmd>DiffviewClose<cr>', { desc = 'Diffview: close' })
vim.keymap.set('n', '<leader>Ph', '<cmd>DiffviewFileHistory<cr>', { desc = 'Diffview: file history' })
