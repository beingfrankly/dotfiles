require('conform').setup {
  notify_on_error = false,
  formatters_by_ft = {
    lua = { 'stylua' },
    html = { 'prettier' },
    htmlangular = { 'prettier' },
    typescript = { 'prettier' },
    typescriptreact = { 'prettier' },
    json = { 'prettier' },
    jsonc = { 'prettier' },
    javascript = { 'prettier' },
    css = { 'prettier' },
    scss = { 'prettier' },
    yaml = { 'prettier' },
    markdown = { 'prettier' },
  },
}
