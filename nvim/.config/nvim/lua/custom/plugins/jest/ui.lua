-- UI management for Jest test runner (split windows, output display)

local config = require 'custom.plugins.jest.config'
local utils = require 'custom.utils'

local M = {}

--- Get or create test output window
---@return number winnr Window number
---@return number bufnr Buffer number
function M.get_or_create_test_window()
  -- Check if window still exists and is valid
  if utils.is_window_valid(config.state.test_win) then
    return config.state.test_win, config.state.test_buf
  end

  -- Check if buffer still exists (window was closed but buffer remains)
  if utils.is_buffer_valid(config.state.test_buf) then
    -- Reuse existing buffer with new window
    local win, buf = utils.create_split_window {
      direction = config.config.split_direction,
      size = config.config.split_size,
      buf = config.state.test_buf,
      focus = config.config.focus_after_run,
    }

    config.state.test_win = win
    return win, buf
  end

  -- Create new split and buffer
  local buf = utils.create_scratch_buffer('Jest Output', {
    buftype = 'nofile',
    bufhidden = 'wipe',
    swapfile = false,
  })

  -- Add keymaps to close the window
  utils.add_close_keymaps(buf)

  local win = utils.create_split_window {
    direction = config.config.split_direction,
    size = config.config.split_size,
    buf = buf,
    focus = config.config.focus_after_run,
  }

  -- Store references
  config.state.test_win = win
  config.state.test_buf = buf

  return win, buf
end

--- Display test output in split window
---@param output string[] Lines of output to display
---@param title string|nil Window title (default: 'Jest Test Output')
function M.show_output(output, title)
  title = title or 'Jest Test Output'

  local win, buf = M.get_or_create_test_window()

  -- Clear existing content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

  -- Add header
  local content = {
    '─────────────────────────────────────',
    title,
    '─────────────────────────────────────',
    '',
  }

  vim.list_extend(content, output)

  -- Set content
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, content)

  return win, buf
end

--- Display error output in split window
---@param test_results table Map of test results
---@param stderr_output string[] Stderr output lines
function M.show_error_output(test_results, stderr_output)
  -- Check if there are failures
  local has_failures = false
  for _, result in pairs(test_results) do
    if result.status == 'failed' then
      has_failures = true
      break
    end
  end

  if not has_failures or not config.config.show_split_on_error then
    return
  end

  M.show_output(stderr_output, 'Jest Test Results (Failures)')
end

--- Toggle test output window visibility
function M.toggle_output()
  if utils.is_window_valid(config.state.test_win) then
    vim.api.nvim_win_close(config.state.test_win, true)
    config.state.test_win = nil
  else
    M.get_or_create_test_window()
  end
end

--- Close test output window if open
function M.close_output()
  if utils.is_window_valid(config.state.test_win) then
    vim.api.nvim_win_close(config.state.test_win, true)
    config.state.test_win = nil
  end
end

return M
