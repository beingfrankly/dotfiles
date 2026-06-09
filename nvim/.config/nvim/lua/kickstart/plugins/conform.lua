require('conform').setup {
  notify_on_error = false,
  formatters_by_ft = {
    lua = { 'stylua' },
    html = { 'prettier' },
    htmlangular = { 'prettier' },
    typescript = { 'prettier' },
    json = { 'prettier' },
    javascript = { 'prettier' },
  },
}
