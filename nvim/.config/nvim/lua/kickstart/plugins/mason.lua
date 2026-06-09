require('mason').setup {
  ui = {
    border = 'rounded',
    width = 0.8,
    height = 0.8,
    icons = {
      package_installed = '✓',
      package_pending = '➜',
      package_uninstalled = '✗',
    },
  },
}

-- Auto-install tools on startup
local ensure_installed = {
  -- LSP servers
  'lua-language-server',
  'tsgo',
  'astro-language-server',
  'html-lsp',
  'json-lsp',
  { 'angular-language-server', version = '18.2.0' },

  -- Formatters
  'stylua',
  'prettier',
}

local registry = require 'mason-registry'

registry.refresh(function()
  for _, tool in ipairs(ensure_installed) do
    local name = type(tool) == 'table' and tool[1] or tool
    local version = type(tool) == 'table' and tool.version or nil
    local p = registry.get_package(name)
    if not p:is_installed() then
      vim.notify('Installing ' .. name .. (version and (' v' .. version) or '') .. ' via Mason...', vim.log.levels.INFO)
      p:install({ version = version })
    end
  end
end)
