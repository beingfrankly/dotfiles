-- User-facing command implementations for Jest test runner

local config = require 'custom.plugins.jest.config'
local runner = require 'custom.plugins.jest.runner'
local treesitter = require 'custom.plugins.jest.treesitter'
local ui = require 'custom.plugins.jest.ui'
local utils = require 'custom.utils'

local M = {}

--- Run the nearest test at cursor in watch mode
function M.run_nearest_test()
  local test_name = treesitter.build_test_name_pattern()
  if not test_name then
    return
  end

  local filepath = utils.get_relative_path()
  local args = string.format("%s -t '%s' --watch", filepath, test_name)

  utils.notify_info('Running test in watch mode: ' .. test_name)
  runner.run_jest(args, true)
end

--- Run all tests in the current file
function M.run_file()
  local filepath = utils.get_relative_path()
  utils.notify_info 'Running all tests in file'
  runner.run_jest(filepath, false)
end

--- Run all tests in the current file in watch mode
function M.run_file_watch()
  local filepath = utils.get_relative_path()
  utils.notify_info 'Running tests in watch mode'
  runner.run_jest(filepath .. ' --watch', true)
end

--- Run tests with coverage
function M.run_with_coverage()
  local filepath = utils.get_relative_path()
  utils.notify_info 'Running tests with coverage'
  runner.run_jest(filepath .. ' --coverage', false)
end

--- Run tests in debug mode
function M.run_debug()
  local filepath = utils.get_relative_path()
  utils.notify_info 'Running tests in debug mode'
  utils.notify_info 'Attach debugger to process on port 9229'
  runner.run_jest('--inspect-brk --runInBand ' .. filepath, false)
end

--- Re-run the last test command
function M.run_last()
  if not config.state.last_test_cmd then
    utils.notify_warn 'No previous test run'
    return
  end

  utils.notify_info 'Re-running last test'

  -- Detect if last command had --watch
  local has_watch = config.state.last_test_cmd:find('--watch') ~= nil

  -- Remove jest_cmd prefix and re-run
  local args = config.state.last_test_cmd:gsub('^' .. config.config.jest_cmd .. ' ', '')
  runner.run_jest(args, has_watch)
end

--- Stop running tests
function M.stop_tests()
  runner.stop_tests()
end

--- Toggle test output window visibility
function M.toggle_output()
  ui.toggle_output()
end

--- Command definitions for setup
--- Each entry defines both a user command and keybinding
M.command_definitions = {
  {
    name = 'JestNearest',
    fn = M.run_nearest_test,
    desc = 'Run nearest test',
    key = 'tt',
    key_desc = 'Run nearest [T]est',
  },
  {
    name = 'JestFile',
    fn = M.run_file,
    desc = 'Run all tests in file',
    key = 'tf',
    key_desc = 'Run [F]ile',
  },
  {
    name = 'JestWatch',
    fn = M.run_file_watch,
    desc = 'Run tests in watch mode',
    key = 'tw',
    key_desc = '[W]atch mode',
  },
  {
    name = 'JestCoverage',
    fn = M.run_with_coverage,
    desc = 'Run tests with coverage',
    key = 'tc',
    key_desc = '[C]overage',
  },
  {
    name = 'JestDebug',
    fn = M.run_debug,
    desc = 'Run tests in debug mode',
    key = 'td',
    key_desc = '[D]ebug mode',
  },
  {
    name = 'JestLast',
    fn = M.run_last,
    desc = 'Re-run last test',
    key = 'tl',
    key_desc = '[L]ast test',
  },
  {
    name = 'JestStop',
    fn = M.stop_tests,
    desc = 'Stop running tests',
    key = 'ts',
    key_desc = '[S]top tests',
  },
  {
    name = 'JestToggle',
    fn = M.toggle_output,
    desc = 'Toggle test output window',
    key = 'to',
    key_desc = 'Toggle [O]utput',
  },
}

return M
