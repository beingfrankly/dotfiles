-- Configuration and state management for Jest test runner

local constants = require 'custom.plugins.jest.constants'
local utils = require 'custom.utils'

local M = {}

-- Configuration with defaults
M.config = vim.deepcopy(constants.DEFAULT_CONFIG)

-- State management
M.state = {
  last_test_cmd = nil,
  test_buf = nil,
  test_win = nil,
  test_job = nil,
  spinner = nil, -- Spinner instance
  virtual_text_marks = {},
}

--- Validate and merge user configuration
---@param opts table|nil User configuration options
function M.setup(opts)
  opts = opts or {}

  -- Validate split_direction
  if opts.split_direction then
    local valid = false
    for _, dir in pairs(constants.VALID_SPLIT_DIRECTIONS) do
      if opts.split_direction == dir then
        valid = true
        break
      end
    end

    if not valid then
      utils.notify_warn('Invalid split_direction, using horizontal')
      opts.split_direction = constants.VALID_SPLIT_DIRECTIONS.HORIZONTAL
    end
  end

  -- Validate split_size
  if opts.split_size and (type(opts.split_size) ~= 'number' or opts.split_size < 1) then
    utils.notify_warn('Invalid split_size, using 15')
    opts.split_size = 15
  end

  -- Merge with defaults
  M.config = vim.tbl_deep_extend('force', M.config, opts)
end

--- Reset state (useful for testing or cleanup)
function M.reset_state()
  if M.state.spinner then
    M.state.spinner:stop()
  end

  if M.state.test_job then
    M.state.test_job:shutdown()
  end

  M.state = {
    last_test_cmd = nil,
    test_buf = nil,
    test_win = nil,
    test_job = nil,
    spinner = nil,
    virtual_text_marks = {},
  }
end

--- Check if current file is a test file
---@return boolean
function M.is_test_file()
  return utils.file_matches_pattern(nil, constants.TEST_FILE_PATTERNS)
end

--- Find the nearest jest.config file by walking up from current file
---@return string|nil Relative path to config file
function M.find_jest_config()
  return utils.find_file_in_ancestors(constants.JEST_CONFIG_FILES)
end

--- Stop the spinner if one is running
function M.stop_spinner()
  if M.state.spinner then
    M.state.spinner:stop()
    M.state.spinner = nil
  end
end

return M
