-- Virtual text and spinner management for Jest test runner

local constants = require 'custom.plugins.jest.constants'
local utils = require 'custom.utils'

local M = {}

-- Namespace for virtual text extmarks
M.ns_id = vim.api.nvim_create_namespace 'jest_runner'

--- Clear all virtual text and diagnostics in buffer
---@param bufnr number|nil Buffer number (nil for current buffer)
function M.clear_virtual_text(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not utils.is_buffer_valid(bufnr) then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, M.ns_id, 0, -1)
  vim.diagnostic.set(M.ns_id, bufnr, {}, {})
end

--- Set virtual text on a specific line
---@param bufnr number Buffer number
---@param line number Line number (0-indexed)
---@param text string Virtual text content
---@param hl_group string Highlight group name
---@return number|nil mark_id Extmark ID or nil if failed
function M.set_virtual_text(bufnr, line, text, hl_group)
  if not utils.is_buffer_valid(bufnr) then
    return nil
  end

  -- Clear existing mark on this line
  local existing_marks = vim.api.nvim_buf_get_extmarks(bufnr, M.ns_id, { line, 0 }, { line, -1 }, {})
  for _, mark in ipairs(existing_marks) do
    vim.api.nvim_buf_del_extmark(bufnr, M.ns_id, mark[1])
  end

  -- Set new virtual text
  local mark_id = vim.api.nvim_buf_set_extmark(bufnr, M.ns_id, line, 0, {
    virt_text = { { text, hl_group } },
    virt_text_pos = 'eol',
  })

  return mark_id
end

--- Set LSP diagnostics for failed tests
---@param bufnr number Buffer number
---@param diagnostics table[] Array of diagnostic entries
function M.set_diagnostics(bufnr, diagnostics)
  if not utils.is_buffer_valid(bufnr) then
    return
  end

  vim.diagnostic.set(M.ns_id, bufnr, diagnostics, {})
end

-- ============================================================================
-- Spinner Animation
-- ============================================================================

local Spinner = {}
Spinner.__index = Spinner

--- Create a new spinner instance
---@param bufnr number Buffer number
---@param lines number[] Array of line numbers to show spinner on
---@return table Spinner instance
function Spinner:new(bufnr, lines)
  local instance = {
    bufnr = bufnr,
    lines = lines,
    timer = nil,
    frame = 1,
  }
  setmetatable(instance, Spinner)
  return instance
end

--- Start the spinner animation
function Spinner:start()
  -- Stop any existing timer first
  if self.timer then
    self:stop()
  end

  self.timer = vim.loop.new_timer()
  if not self.timer then
    return
  end

  self.frame = 1

  local spinner_ref = self -- Capture self for callback

  self.timer:start(
    0,
    constants.SPINNER_UPDATE_INTERVAL,
    function()
      -- Schedule the actual work on vim's main loop
      vim.schedule(function()
        -- Check if buffer is still valid
        if not utils.is_buffer_valid(spinner_ref.bufnr) then
          vim.schedule(function()
            spinner_ref:stop()
          end)
          return
        end

        -- Check if timer was stopped externally
        if not spinner_ref.timer then
          return
        end

        spinner_ref:update()
      end)
    end
  )
end

--- Update spinner frame
function Spinner:update()
  -- Validate buffer before updating
  if not utils.is_buffer_valid(self.bufnr) then
    self:stop()
    return
  end

  local frame = constants.SPINNER_FRAMES[self.frame]

  -- Update each line with error handling
  for _, line in ipairs(self.lines) do
    local ok = pcall(M.set_virtual_text, self.bufnr, line, '  ' .. frame .. ' running...', constants.HIGHLIGHT_GROUPS.RUNNING)
    if not ok then
      -- Buffer might have been closed, stop spinner
      self:stop()
      return
    end
  end

  self.frame = self.frame + 1
  if self.frame > #constants.SPINNER_FRAMES then
    self.frame = 1
  end
end

--- Stop the spinner animation
function Spinner:stop()
  if self.timer then
    -- Use pcall to safely stop and close timer
    pcall(function()
      self.timer:stop()
      self.timer:close()
    end)
    self.timer = nil
  end
end

--- Check if spinner is running
---@return boolean
function Spinner:is_running()
  return self.timer ~= nil
end

-- Export Spinner class
M.Spinner = Spinner

return M
