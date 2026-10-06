require('markview').setup {
  preview = {
    icon_provider = 'devicons',
  },
}

vim.api.nvim_create_autocmd('BufWinEnter', {
  group = vim.api.nvim_create_augroup('hwf-review-window', { clear = true }),
  pattern = '*/.scratch/*/review.md',
  callback = function(args)
    vim.keymap.set('n', '<CR>', 'gF', { buffer = args.buf, desc = 'Open the file under the cursor' })
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = 'no'
    vim.opt_local.foldcolumn = '0'
    vim.opt_local.statuscolumn = ''
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
  end,
})

local configured = false

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function()
    if configured then
      return
    end
    configured = true

    -- vim-table-mode
    vim.g.table_mode_corner = '|'

    -- Keymaps
    vim.keymap.set('n', '<leader>mp', '<cmd>MarkdownPreviewToggle<cr>', { desc = '[M]arkdown [P]review' })
    vim.keymap.set('n', '<leader>mt', '<cmd>TableModeToggle<cr>', { desc = '[M]arkdown [T]able mode' })
  end,
})
