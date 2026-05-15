-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Load centralized keymaps
-- require('kickstart.config.keymaps').setup()

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
-- vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Create splits
vim.keymap.set('n', '<leader>|', '<cmd>vsplit<CR>', { desc = 'Split window vertically' })
vim.keymap.set('n', '<leader>-', '<cmd>split<CR>', { desc = 'Split window horizontally' })
vim.keymap.set('n', '<leader>x', '<cmd>close<CR>', { desc = 'Close current split' })

-- Resize splits with arrow keys
vim.keymap.set('n', '<C-Up>', '<cmd>resize +2<CR>', { desc = 'Increase window height' })
vim.keymap.set('n', '<C-Down>', '<cmd>resize -2<CR>', { desc = 'Decrease window height' })
vim.keymap.set('n', '<C-Left>', '<cmd>vertical resize -2<CR>', { desc = 'Decrease window width' })
vim.keymap.set('n', '<C-Right>', '<cmd>vertical resize +2<CR>', { desc = 'Increase window width' })

-- Equalize splits
vim.keymap.set('n', '<leader>=', '<C-w>=', { desc = 'Equalize split sizes' })

-- ═══════════════════════════════════════════════════════════
-- ERGONOMIC NAVIGATION
-- ═══════════════════════════════════════════════════════════

-- Line start/end (Helix-inspired, more comfortable than $ and ^)
vim.keymap.set('n', 'gl', '$', { desc = 'Go to end of line' })
vim.keymap.set('n', 'gh', '^', { desc = 'Go to start of line' })

-- Smart j/k: visual lines when no count, real lines with count
vim.keymap.set({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
vim.keymap.set({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })

-- Smart n/N: n always forward, N always backward
vim.keymap.set('n', 'n', "'Nn'[v:searchforward].'zv'", { expr = true, desc = 'Next Search Result' })
vim.keymap.set('x', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next Search Result' })
vim.keymap.set('o', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next Search Result' })
vim.keymap.set('n', 'N', "'nN'[v:searchforward].'zv'", { expr = true, desc = 'Prev Search Result' })
vim.keymap.set('x', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev Search Result' })
vim.keymap.set('o', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev Search Result' })

-- ═══════════════════════════════════════════════════════════
-- LINE MOVEMENT
-- ═══════════════════════════════════════════════════════════

-- Move lines up/down with Alt+j/k (with count support + auto-indent)
vim.keymap.set('n', '<A-j>', "<cmd>execute 'move .+' . v:count1<cr>==", { desc = 'Move Down' })
vim.keymap.set('n', '<A-k>', "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = 'Move Up' })
vim.keymap.set('i', '<A-j>', '<esc><cmd>m .+1<cr>==gi', { desc = 'Move Down' })
vim.keymap.set('i', '<A-k>', '<esc><cmd>m .-2<cr>==gi', { desc = 'Move Up' })
vim.keymap.set('v', '<A-j>', ":move '>+1<CR>gv=gv", { desc = 'Move Down' })
vim.keymap.set('v', '<A-k>', ":move '<-2<CR>gv=gv", { desc = 'Move Up' })

-- ═══════════════════════════════════════════════════════════
-- SMART EDITING
-- ═══════════════════════════════════════════════════════════

-- Better indenting (stay in visual mode)
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

-- Better paste (doesn't replace clipboard with deleted text)
vim.keymap.set('v', 'p', '"_dP')

-- Undo break-points at logical stops
vim.keymap.set('i', ',', ',<c-g>u')
vim.keymap.set('i', '.', '.<c-g>u')
vim.keymap.set('i', ';', ';<c-g>u')

-- ═══════════════════════════════════════════════════════════
-- UTILITY
-- ═══════════════════════════════════════════════════════════

-- Save file (works in all modes)
vim.keymap.set({ 'i', 'x', 'n', 's' }, '<C-s>', '<cmd>w<cr><esc>', { desc = 'Save File' })

-- Redraw / Clear hlsearch / Diff Update
vim.keymap.set('n', '<leader>ur', '<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>', { desc = 'Redraw / Clear hlsearch / Diff Update' })

-- Terminal mode navigation
vim.keymap.set('t', '<esc><esc>', '<c-\\><c-n>', { desc = 'Enter Normal Mode' })
vim.keymap.set('t', '<C-h>', '<cmd>wincmd h<cr>', { desc = 'Go to Left Window' })
vim.keymap.set('t', '<C-j>', '<cmd>wincmd j<cr>', { desc = 'Go to Lower Window' })
vim.keymap.set('t', '<C-k>', '<cmd>wincmd k<cr>', { desc = 'Go to Upper Window' })
vim.keymap.set('t', '<C-l>', '<cmd>wincmd l<cr>', { desc = 'Go to Right Window' })

-- Smart fold navigation
vim.keymap.set('n', 'zv', 'zMzvzz', { desc = 'Close all folds except the current one' })
vim.keymap.set('n', 'zj', 'zcjzOzz', { desc = 'Close current fold, open next fold' })
vim.keymap.set('n', 'zk', 'zckzOzz', { desc = 'Close current fold, open previous fold' })

-- Execute find_project_dirs function from scopes plugin
-- vim.keymap.set('n', '<leader>fp', function()
--   local scopes = require('kickstart.plugins.scopes')
--   scopes.write_projects()
-- end, { desc = '[F]ind [P]roject directories' })

-- Select projects in current git repository (now configured in lua/kickstart/config/keymaps.lua)

-- Git worktree picker
vim.keymap.set('n', '<leader>gw', function()
  require('lib.worktree').pick_worktree()
end, { desc = '[G]it [W]orktrees' })

-- Git remote branch picker (create worktree)
vim.keymap.set('n', '<leader>gr', function()
  require('lib.worktree').pick_remote_branch()
end, { desc = '[G]it [R]emote branches (create worktree)' })

-- Git worktree: switch to PR via worktrunk
vim.keymap.set('n', '<leader>gP', function()
  require('lib.worktree').pick_pr_and_switch()
end, { desc = 'Worktree: switch to PR' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- vim: ts=2 sts=2 sw=2 et
