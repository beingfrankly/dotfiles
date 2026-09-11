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

local function tool_name(tool)
  return type(tool) == 'table' and tool[1] or tool
end

local function missing_tools()
  local registry = require 'mason-registry'
  local missing = {}
  for _, tool in ipairs(ensure_installed) do
    local ok, p = pcall(registry.get_package, tool_name(tool))
    if ok and not p:is_installed() then
      missing[#missing + 1] = tool
    end
  end
  return missing
end

local function install(tools)
  if #tools == 0 then
    vim.notify('Mason: every required tool is installed', vim.log.levels.INFO)
    return
  end

  local registry = require 'mason-registry'
  registry.refresh(function()
    for _, tool in ipairs(tools) do
      local name = tool_name(tool)
      local version = type(tool) == 'table' and tool.version or nil
      local p = registry.get_package(name)
      if not p:is_installed() then
        vim.notify('Installing ' .. name .. (version and (' v' .. version) or '') .. ' via Mason...', vim.log.levels.INFO)
        p:install({ version = version })
      end
    end
  end)
end

vim.api.nvim_create_user_command('MasonEnsureInstalled', function()
  install(missing_tools())
end, { desc = 'Install the Mason tools this config requires' })

vim.api.nvim_create_autocmd('UIEnter', {
  once = true,
  callback = function()
    vim.schedule(function()
      local missing = missing_tools()
      if #missing > 0 then
        install(missing)
      end
    end)
  end,
})
