-- Mason.nvim configuration for automatic tool installation
-- Manages LSP servers, formatters, linters, and debug adapters
return {
  'williamboman/mason.nvim',
  config = function()
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
    -- Entries can be a string or { 'name', version = 'x.y.z' } for pinned versions
    local ensure_installed = {
      -- LSP servers
      'lua-language-server', -- Lua
      'tsgo', -- TypeScript/JavaScript
      'astro-language-server', -- Astro
      'html-lsp', -- HTML
      'json-lsp', -- JSON
      { 'angular-language-server', version = '18.2.0' }, -- Angular (pin to match project's Angular v18)

      -- Formatters
      'stylua', -- Lua formatter
      'prettier', -- Multi-language formatter
    }

    -- Install tools if not already installed
    local registry = require 'mason-registry'

    -- Ensure registry is ready
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
  end,
}
