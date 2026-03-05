-- Core Jest execution logic

local config = require 'custom.plugins.jest.config'
local constants = require 'custom.plugins.jest.constants'
local parser = require 'custom.plugins.jest.parser'
local treesitter = require 'custom.plugins.jest.treesitter'
local ui = require 'custom.plugins.jest.ui'
local utils = require 'custom.utils'
local virtual_text = require 'custom.plugins.jest.virtual_text'

local M = {}

--- Build Jest command with config detection
---@param args string Command arguments
---@return string Full command string
local function build_jest_command(args)
  local cmd = config.config.jest_cmd

  -- Add config file if auto-detection is enabled
  if config.config.auto_detect_config then
    local config_file = config.find_jest_config()
    if config_file then
      cmd = cmd .. ' --config ' .. config_file
    end
  end

  -- Add JSON output flag for parsing results
  cmd = cmd .. ' --json ' .. args

  return cmd
end

--- Setup virtual text spinner for test run
---@param bufnr number Buffer number
---@param args string Jest arguments
local function setup_spinner(bufnr, args)
  -- Stop any existing spinner first
  if config.state.spinner then
    config.state.spinner:stop()
    config.state.spinner = nil
  end

  if not config.config.use_virtual_text then
    return
  end

  local test_pattern = treesitter.extract_test_pattern(args)
  local test_lines = treesitter.collect_test_lines_for_pattern(bufnr, test_pattern)

  if #test_lines == 0 then
    return
  end

  -- Create and store spinner in state
  config.state.spinner = virtual_text.Spinner:new(bufnr, test_lines)
  config.state.spinner:start()
end

--- Kill existing test job if running
local function kill_existing_job()
  if config.state.test_job then
    config.state.test_job:shutdown()
  end
end

--- Check if Jest is starting a new test run in watch mode
---@param line string Stderr line to check
---@return boolean
local function is_watch_mode_test_start(line)
  for _, pattern in ipairs(constants.WATCH_MODE_PATTERNS) do
    if line:match(pattern) then
      return true
    end
  end
  return false
end

--- Create stdout callback for Jest output processing
---@param json_parser table JsonParser instance
---@param source_bufnr number Source buffer number
---@param is_watch_mode boolean Whether in watch mode
---@return function Callback function
local function create_stdout_callback(json_parser, source_bufnr, is_watch_mode)
  return vim.schedule_wrap(function(_, line)
    if not line then
      return
    end

    json_parser:add_line(line)

    -- In watch mode, try to parse JSON incrementally
    if is_watch_mode and config.config.use_virtual_text then
      json_parser:try_parse(source_bufnr)
    end
  end)
end

--- Create stderr callback for Jest stderr processing
---@param stderr_output table Array to collect stderr lines
---@param json_parser table JsonParser instance
---@param source_bufnr number Source buffer number
---@param args string Jest arguments
---@param is_watch_mode boolean Whether in watch mode
---@return function Callback function
local function create_stderr_callback(stderr_output, json_parser, source_bufnr, args, is_watch_mode)
  return vim.schedule_wrap(function(_, line)
    if not line then
      return
    end

    table.insert(stderr_output, line)

    -- In watch mode, detect when Jest starts running tests again
    if is_watch_mode and json_parser:has_results() then
      if is_watch_mode_test_start(line) then
        -- Restart spinner for new test run
        setup_spinner(source_bufnr, args)
      end
    end
  end)
end

--- Create exit callback for Jest process completion
---@param json_parser table JsonParser instance
---@param stderr_output table Array of stderr lines
---@param source_bufnr number Source buffer number
---@param is_watch_mode boolean Whether in watch mode
---@return function Callback function
local function create_exit_callback(json_parser, stderr_output, source_bufnr, is_watch_mode)
  return vim.schedule_wrap(function(j, exit_code)
    -- Stop spinner if running
    config.stop_spinner()

    -- Only clean up if not in watch mode
    if not is_watch_mode then
      -- Try to parse final JSON results
      local full_json = table.concat(json_parser.json_lines, '\n')
      local test_results = parser.parse_jest_results(full_json)

      if test_results and config.config.use_virtual_text then
        -- Apply virtual text results
        parser.apply_test_results(source_bufnr, test_results)

        -- Show split window only on errors if configured
        ui.show_error_output(test_results, stderr_output)
      else
        -- Fallback: show split window with output if JSON parsing failed
        local all_output = vim.list_extend({}, json_parser.json_lines)
        vim.list_extend(all_output, stderr_output)
        ui.show_output(all_output)
      end

      config.state.test_job = nil
    end
  end)
end

--- Run a Jest command
---@param args string Jest arguments (file path, flags, etc.)
---@param is_watch_mode boolean Whether to run in watch mode
function M.run_jest(args, is_watch_mode)
  if not config.is_test_file() then
    utils.notify_warn 'Current file is not a test file'
    return
  end

  local Job = require 'plenary.job'
  local Path = require 'plenary.path'
  local source_bufnr = vim.api.nvim_get_current_buf()

  -- Find jest.config to determine working directory
  local jest_config_path = config.find_jest_config()
  local jest_cwd = vim.fn.getcwd()

  if jest_config_path then
    -- jest_config_path is relative to CWD, so get its directory
    -- and make it absolute by joining with CWD
    local relative_config_dir = vim.fn.fnamemodify(jest_config_path, ':h')
    jest_cwd = vim.fn.fnamemodify(relative_config_dir, ':p')
  end

  -- Build command
  local cmd = build_jest_command(args)

  -- Save command for re-running
  config.state.last_test_cmd = cmd

  -- Clear previous virtual text
  virtual_text.clear_virtual_text(source_bufnr)

  -- Setup spinner
  setup_spinner(source_bufnr, args)

  -- Kill existing job
  kill_existing_job()

  -- Create JSON parser
  local json_parser = parser.JsonParser:new()
  local stderr_output = {}

  -- Get shell configuration
  local shell, shell_flag = utils.get_shell_config()

  -- Create callbacks
  local on_stdout = create_stdout_callback(json_parser, source_bufnr, is_watch_mode)
  local on_stderr = create_stderr_callback(stderr_output, json_parser, source_bufnr, args, is_watch_mode)
  local on_exit = create_exit_callback(json_parser, stderr_output, source_bufnr, is_watch_mode)

  -- Run the command using plenary.job
  config.state.test_job = Job:new {
    command = shell,
    args = { shell_flag, cmd },
    cwd = jest_cwd, -- Use directory containing jest.config
    on_stdout = on_stdout,
    on_stderr = on_stderr,
    on_exit = on_exit,
  }

  config.state.test_job:start()
end

--- Stop running tests
function M.stop_tests()
  if config.state.test_job then
    config.state.test_job:shutdown()

    -- Stop spinner if running
    config.stop_spinner()

    -- Clear virtual text
    virtual_text.clear_virtual_text()

    utils.notify_info 'Stopped running tests'
    config.state.test_job = nil
  else
    utils.notify_warn 'No tests running'
  end
end

return M
