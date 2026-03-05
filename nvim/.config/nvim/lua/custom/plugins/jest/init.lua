-- Jest test runner plugin for Neovim
-- Provides commands and keybindings to run Jest tests with inline virtual text results

local commands = require 'custom.plugins.jest.commands'
local config = require 'custom.plugins.jest.config'
local utils = require 'custom.utils'

local M = {}

--- Setup the Jest test runner plugin
---@param opts table|nil Configuration options
function M.setup(opts)
  -- Setup configuration
  config.setup(opts)

  -- Register all commands and keybindings
  for _, cmd in ipairs(commands.command_definitions) do
    -- Create user command
    vim.api.nvim_create_user_command(cmd.name, cmd.fn, { desc = cmd.desc })

    -- Create keybinding
    vim.keymap.set('n', '<leader>' .. cmd.key, cmd.fn, {
      desc = '[T]est: ' .. cmd.key_desc,
    })
  end

  utils.notify_info 'Jest test runner loaded'
end

-- Export command functions for direct use
M.run_nearest_test = commands.run_nearest_test
M.run_file = commands.run_file
M.run_file_watch = commands.run_file_watch
M.run_with_coverage = commands.run_with_coverage
M.run_debug = commands.run_debug
M.run_last = commands.run_last
M.stop_tests = commands.stop_tests
M.toggle_output = commands.toggle_output

return M
