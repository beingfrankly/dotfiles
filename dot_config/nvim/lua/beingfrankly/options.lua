vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.opt.clipboard = 'unnamedplus'

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Don't store backup while overwriting the file
vim.opt.backup = false
vim.opt.writebackup = false

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.fillchars = {
  eob = ' ',
  diff = '╱',
  foldopen = '',
  foldclose = '',
  foldsep = ' ',
}
-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

vim.opt.cmdheight = 0

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true

-- global statusline
vim.opt.laststatus = 3 -- disable nvim intro

vim.opt.shortmess:append 'sI'

-- Reduce command line messages
vim.opt.shortmess:append 'WcC'

-- enable 24-bit colour
vim.opt.termguicolors = true

vim.opt.swapfile = false

vim.opt.compatible = false

-- max items in autocomplete menu
vim.opt.pumheight = 15

-- don't scroll after splitting
vim.opt.splitkeep = 'screen'

-- NOTE: horizontal scrolling can be laggy with large horizontal lines because of regex highlighting
vim.opt.wrap = false

if vim.fn.has 'nvim-0.10' == 1 then
  vim.opt.smoothscroll = true
end
