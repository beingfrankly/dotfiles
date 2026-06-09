-- lualine.nvim: statusline
-- https://github.com/nvim-lualine/lualine.nvim
-- Replaces mini.statusline. Uses 'auto' theme to follow the colorscheme.

local lualine = require('kickstart.util').try_require('lualine', 'lualine.nvim')
if not lualine then return end

local function lsp_clients()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    return ''
  end
  local names = {}
  for _, c in ipairs(clients) do
    table.insert(names, c.name)
  end
  return ' ' .. table.concat(names, ',')
end

lualine.setup({
  options = {
    theme = 'auto',
    globalstatus = true,
    icons_enabled = vim.g.have_nerd_font,
    section_separators = { left = '', right = '' },
    component_separators = { left = '\u{2502}', right = '\u{2502}' },
    disabled_filetypes = {
      statusline = {
        'dashboard',
        'alpha',
        'snacks_dashboard',
        'snacks_picker_input',
        'snacks_picker_list',
        'yazi',
        'lazy',
        'mason',
        'TelescopePrompt',
      },
    },
  },
  sections = {
    lualine_a = {
      {
        'mode',
        fmt = function(str)
          return str:sub(1, 1)
        end,
      },
    },
    lualine_b = {
      'branch',
      {
        'diff',
        symbols = { added = '+', modified = '~', removed = '-' },
      },
    },
    lualine_c = {
      {
        'filename',
        path = 1,
        symbols = {
          modified = '\u{25CF}',
          readonly = '[RO]',
          unnamed = '[No Name]',
          newfile = '[New]',
        },
      },
    },
    lualine_x = {
      {
        'diagnostics',
        sources = { 'nvim_diagnostic' },
        symbols = { error = 'E', warn = 'W', info = 'I', hint = 'H' },
      },
      {
        lsp_clients,
        cond = function()
          return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end,
      },
      {
        function()
          local map = { claude = 'Claude', codex = 'Codex' }
          return '\u{F085} ' .. (map[vim.g.sidekick_active] or vim.g.sidekick_active or '')
        end,
        cond = function()
          return vim.g.sidekick_active ~= nil
        end,
      },
      {
        function()
          return '\u{F407} ' .. (vim.g.atlas_active or '')
        end,
        cond = function()
          return vim.g.atlas_active ~= nil
        end,
      },
      'filetype',
    },
    lualine_y = {},
    lualine_z = {},
  },
  extensions = { 'quickfix', 'man', 'mason', 'nvim-dap-ui' },
})
