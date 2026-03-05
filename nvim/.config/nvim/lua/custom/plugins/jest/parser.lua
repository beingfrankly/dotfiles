-- JSON parser for Jest test output

local constants = require 'custom.plugins.jest.constants'
local virtual_text = require 'custom.plugins.jest.virtual_text'
local treesitter = require 'custom.plugins.jest.treesitter'
local utils = require 'custom.utils'

local M = {}

-- Lazy load config to avoid circular dependency
local config = nil
local function get_config()
  if not config then
    config = require 'custom.plugins.jest.config'
  end
  return config
end

--- Parse Jest JSON output and map results to tests
---@param json_output string Raw JSON output from Jest
---@return table|nil Map of test name to result info
function M.parse_jest_results(json_output)
  local ok, results = pcall(vim.json.decode, json_output)
  if not ok then
    return nil
  end

  local test_results = {}

  -- Jest JSON structure: results.testResults[].assertionResults[]
  if results.testResults then
    for _, file_result in ipairs(results.testResults) do
      if file_result.assertionResults then
        for _, assertion in ipairs(file_result.assertionResults) do
          -- Build full test name from ancestorTitles + title
          local full_name_parts = vim.list_extend({}, assertion.ancestorTitles or {})
          table.insert(full_name_parts, assertion.title)
          local full_name = table.concat(full_name_parts, ' ')

          test_results[full_name] = {
            status = assertion.status,
            duration = assertion.duration,
            failureMessages = assertion.failureMessages or {},
            fullName = full_name,
          }
        end
      end
    end
  end

  return test_results
end

--- Apply test results as virtual text and diagnostics
---@param bufnr number Buffer number
---@param test_results table Map of test name to result
function M.apply_test_results(bufnr, test_results)
  if not utils.is_buffer_valid(bufnr) then
    return
  end

  -- Stop spinner when applying results
  get_config().stop_spinner()

  -- Collect all tests in the file
  local all_tests = treesitter.collect_all_tests(bufnr)

  -- Build diagnostics list for failed tests
  local diagnostics = {}

  -- Match results to line numbers and set virtual text
  for _, test in ipairs(all_tests) do
    local result = test_results[test.full_name]

    -- Only show virtual text for tests that actually ran (passed or failed)
    -- Skip pending/skipped tests
    if result and result.status ~= constants.TEST_STATUS.PENDING and result.status ~= constants.TEST_STATUS.SKIPPED then
      local icon, hl_group

      if result.status == constants.TEST_STATUS.PASSED then
        icon = constants.TEST_ICONS.PASSED
        hl_group = constants.HIGHLIGHT_GROUPS.PASSED
      elseif result.status == constants.TEST_STATUS.FAILED then
        icon = constants.TEST_ICONS.FAILED
        hl_group = constants.HIGHLIGHT_GROUPS.FAILED

        -- Add to diagnostics for failed tests
        local error_msg = 'Test failed'
        if result.failureMessages and #result.failureMessages > 0 then
          -- Extract first line of error message
          error_msg = result.failureMessages[1]:match '^[^\n]*' or result.failureMessages[1]
        end

        table.insert(diagnostics, {
          lnum = test.line,
          col = 0,
          severity = vim.diagnostic.severity.ERROR,
          source = 'jest',
          message = error_msg,
          user_data = {
            test_name = test.full_name,
          },
        })
      else
        icon = constants.TEST_ICONS.UNKNOWN
        hl_group = constants.HIGHLIGHT_GROUPS.UNKNOWN
      end

      -- Simple virtual text: just the icon
      local text = '  ' .. icon
      virtual_text.set_virtual_text(bufnr, test.line, text, hl_group)
    end
  end

  -- Set LSP diagnostics for failed tests
  virtual_text.set_diagnostics(bufnr, diagnostics)
end

-- ============================================================================
-- Incremental JSON Parser (for watch mode)
-- ============================================================================

local JsonParser = {}
JsonParser.__index = JsonParser

--- Create a new JSON parser instance
---@return table Parser instance
function JsonParser:new()
  local instance = {
    json_lines = {},
    last_parsed_pos = 0,
    has_shown_results = false,
  }
  setmetatable(instance, JsonParser)
  return instance
end

--- Add a line to the parser buffer
---@param line string Line to add
function JsonParser:add_line(line)
  table.insert(self.json_lines, line)
end

--- Try to parse accumulated JSON output
---@param bufnr number Buffer number to apply results to
---@return boolean success Whether a complete JSON object was parsed
function JsonParser:try_parse(bufnr)
  local full_json = table.concat(self.json_lines, '\n')

  -- Try to find a complete JSON object
  local json_start = full_json:find('{')
  if not json_start then
    return false
  end

  -- Find matching closing brace
  local depth = 0
  local json_end = nil
  for i = json_start, #full_json do
    local char = full_json:sub(i, i)
    if char == '{' then
      depth = depth + 1
    elseif char == '}' then
      depth = depth - 1
      if depth == 0 then
        json_end = i
        break
      end
    end
  end

  if not json_end then
    return false -- Incomplete JSON
  end

  -- Extract and parse JSON
  local json_str = full_json:sub(json_start, json_end)
  local test_results = M.parse_jest_results(json_str)

  if test_results then
    M.apply_test_results(bufnr, test_results)
    self:reset()
    return true
  end

  return false
end

--- Reset parser state
function JsonParser:reset()
  self.json_lines = {}
  self.last_parsed_pos = 0
  self.has_shown_results = true
end

--- Check if results have been shown
---@return boolean
function JsonParser:has_results()
  return self.has_shown_results
end

-- Export JsonParser class
M.JsonParser = JsonParser

return M
