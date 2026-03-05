return {
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    -- Conform keymaps are now configured in lua/kickstart/config/keymaps.lua
    opts = {
      notify_on_error = false,
      formatters_by_ft = {
        lua = { 'stylua' },
        html = { 'prettier' },
        htmlangular = { 'prettier' },
        typescript = { 'prettier' },
        json = { 'prettier' },
        javascript = { 'prettier' },
      },
    },
  },
}
