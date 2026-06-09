require('gitsigns').setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
  on_attach = function(bufnr)
    local gs = require('gitsigns')
    vim.keymap.set({ 'o', 'x' }, 'ih', gs.select_hunk, { buffer = bufnr, desc = 'Git: inside hunk' })
  end,
}
