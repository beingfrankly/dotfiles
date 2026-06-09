-- Disable netrw (yazi replaces it)
vim.g.loaded_netrwPlugin = 1

require('yazi').setup {
  open_for_directories = true,
  keymaps = {
    show_help = '<f1>',
  },
}
