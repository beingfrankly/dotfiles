-- Common utilities for custom Neovim plugins
-- Provides reusable helpers for buffer, window, and file operations

local M = {}

-- ============================================================================
-- Buffer Operations
-- ============================================================================

--- Check if a buffer is valid and loaded
---@param bufnr number|nil Buffer number (nil for current buffer)
---@return boolean
function M.is_buffer_valid(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end

--- Safely execute an operation on a buffer
---@param bufnr number|nil Buffer number
---@param operation function Function to execute with bufnr as argument
---@return boolean success Whether the operation succeeded
---@return any result Result from operation or error message
function M.safe_buf_operation(bufnr, operation)
  if not M.is_buffer_valid(bufnr) then
    return false, 'Invalid buffer'
  end

  local ok, result = pcall(operation, bufnr)
  if not ok then
    return false, result
  end

  return true, result
end

--- Create a scratch buffer with standard options
---@param name string Buffer name
---@param opts table|nil Options: { buftype, bufhidden, swapfile, modifiable }
---@return number bufnr Buffer number
function M.create_scratch_buffer(name, opts)
  opts = opts or {}
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_option(buf, 'buftype', opts.buftype or 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', opts.bufhidden or 'wipe')
  vim.api.nvim_buf_set_option(buf, 'swapfile', opts.swapfile or false)

  if opts.modifiable ~= nil then
    vim.api.nvim_buf_set_option(buf, 'modifiable', opts.modifiable)
  end

  if name then
    pcall(vim.api.nvim_buf_set_name, buf, name)
  end

  return buf
end

--- Append lines to a buffer safely
---@param bufnr number Buffer number
---@param lines string[] Lines to append
function M.append_to_buffer(bufnr, lines)
  vim.schedule(function()
    if not M.is_buffer_valid(bufnr) then
      return
    end

    local line_count = vim.api.nvim_buf_line_count(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, line_count, line_count, false, lines)
  end)
end

-- ============================================================================
-- Window Operations
-- ============================================================================

--- Check if a window is valid
---@param winnr number|nil Window number (nil for current window)
---@return boolean
function M.is_window_valid(winnr)
  winnr = winnr or vim.api.nvim_get_current_win()
  return winnr and vim.api.nvim_win_is_valid(winnr)
end

--- Create a split window with specified configuration
---@param opts table Options: { direction, size, buf, focus }
---@return number winnr Window number
---@return number bufnr Buffer number
function M.create_split_window(opts)
  opts = opts or {}
  local direction = opts.direction or 'horizontal'
  local size = opts.size or 15
  local buf = opts.buf
  local focus = opts.focus or false

  -- Create split
  local split_cmd = direction == 'vertical' and 'vnew' or 'new'
  vim.cmd(split_cmd)

  local win = vim.api.nvim_get_current_win()

  -- Set buffer if provided
  if buf and M.is_buffer_valid(buf) then
    vim.api.nvim_win_set_buf(win, buf)
  end

  -- Set window size
  if direction == 'vertical' then
    vim.api.nvim_win_set_width(win, size)
  else
    vim.api.nvim_win_set_height(win, size)
  end

  -- Return focus to previous window if requested
  if not focus then
    vim.cmd 'wincmd p'
  end

  return win, vim.api.nvim_win_get_buf(win)
end

--- Add standard keymaps to close a window/buffer
---@param bufnr number Buffer number
---@param keys string[] Keys that should close (default: {'q', '<Esc>'})
function M.add_close_keymaps(bufnr, keys)
  keys = keys or { 'q', '<Esc>' }

  for _, key in ipairs(keys) do
    vim.api.nvim_buf_set_keymap(bufnr, 'n', key, ':close<CR>', {
      noremap = true,
      silent = true,
      desc = 'Close window',
    })
  end
end

-- ============================================================================
-- File Operations
-- ============================================================================

--- Get the current file path relative to project root
---@param filepath string|nil Absolute file path (nil for current buffer)
---@return string Relative path
function M.get_relative_path(filepath)
  local Path = require 'plenary.path'
  local file = filepath and Path:new(filepath) or Path:new(vim.fn.expand '%:p')
  local cwd = Path:new(vim.fn.getcwd())
  return file:make_relative(cwd.filename)
end

--- Check if a filename matches any of the provided patterns
---@param filename string|nil Filename to check (nil for current buffer)
---@param patterns string[] Lua patterns to match against
---@return boolean
function M.file_matches_pattern(filename, patterns)
  filename = filename or vim.fn.expand '%:t'

  for _, pattern in ipairs(patterns) do
    if filename:match(pattern) then
      return true
    end
  end

  return false
end

--- Find a file by walking up from current file to project root
---@param filenames string[] List of filenames to search for
---@param start_path string|nil Starting path (nil for current file)
---@return string|nil Relative path to found file
function M.find_file_in_ancestors(filenames, start_path)
  local Path = require 'plenary.path'
  local current_file = start_path and Path:new(start_path) or Path:new(vim.fn.expand '%:p')
  local root = Path:new(vim.fn.getcwd())

  -- Walk up from current file directory to project root
  for _, dir in ipairs(current_file:parents()) do
    local dir_path = Path:new(dir)

    -- Stop if we've gone above the project root
    if not dir_path:is_absolute() or not vim.startswith(dir_path.filename, root.filename) then
      break
    end

    -- Check for each filename
    for _, filename in ipairs(filenames) do
      local file_path = dir_path / filename
      if file_path:exists() then
        return file_path:make_relative(root.filename)
      end
    end
  end

  return nil
end

-- ============================================================================
-- String Utilities
-- ============================================================================

--- Escape special regex characters for pattern matching
---@param str string String to escape
---@return string Escaped string
function M.escape_pattern(str)
  local result = str:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1')
  return result
end

--- Extract content from a quoted string (removes surrounding quotes)
---@param str string String with quotes
---@return string String without quotes
function M.unquote_string(str)
  return str:match "^['\"`](.+)['\"`]$" or str
end

-- ============================================================================
-- Notification Helpers
-- ============================================================================

--- Show a notification with consistent formatting
---@param message string Message to display
---@param level number|nil Log level (vim.log.levels.INFO by default)
---@param title string|nil Notification title
function M.notify(message, level, title)
  level = level or vim.log.levels.INFO
  vim.notify(message, level, { title = title })
end

--- Show an info notification
---@param message string
---@param title string|nil
function M.notify_info(message, title)
  M.notify(message, vim.log.levels.INFO, title)
end

--- Show a warning notification
---@param message string
---@param title string|nil
function M.notify_warn(message, title)
  M.notify(message, vim.log.levels.WARN, title)
end

--- Show an error notification
---@param message string
---@param title string|nil
function M.notify_error(message, title)
  M.notify(message, vim.log.levels.ERROR, title)
end

-- ============================================================================
-- Shell Utilities
-- ============================================================================

--- Get the shell and shell flag for command execution
---@return string shell Shell executable
---@return string flag Shell flag for command execution (-c or /c)
function M.get_shell_config()
  local shell = vim.o.shell
  local flag = shell:match 'cmd.exe$' and '/c' or '-c'
  return shell, flag
end

return M
