-- Tree-sitter utilities for Jest test detection

local constants = require 'custom.plugins.jest.constants'
local utils = require 'custom.utils'

local M = {}

--- Extract string content from a Tree-sitter node (removes quotes)
---@param node table Tree-sitter node
---@param bufnr number Buffer number
---@return string|nil String content without quotes
local function get_string_content(node, bufnr)
  if not node then
    return nil
  end

  local text = vim.treesitter.get_node_text(node, bufnr)
  if not text then
    return nil
  end

  return utils.unquote_string(text)
end

--- Check if a function name is a test function
---@param func_name string Function name to check
---@return boolean
local function is_test_function(func_name)
  return func_name == constants.TEST_FUNCTION_NAMES.DESCRIBE
    or func_name == constants.TEST_FUNCTION_NAMES.IT
    or func_name == constants.TEST_FUNCTION_NAMES.TEST
end

--- Check if a function is a test block (it/test, not describe)
---@param func_name string Function name to check
---@return boolean
local function is_test_block(func_name)
  return func_name == constants.TEST_FUNCTION_NAMES.IT or func_name == constants.TEST_FUNCTION_NAMES.TEST
end

--- Build a test name pattern for the test at cursor position
--- Walks up the AST tree to collect all describe/it/test names
---@param bufnr number|nil Buffer number (nil for current buffer)
---@return string|nil Escaped test name pattern for Jest -t flag
function M.build_test_name_pattern(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor_pos[1] - 1 -- Convert to 0-indexed

  -- Get Tree-sitter parser
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'typescript')
  if not ok then
    utils.notify_warn 'Tree-sitter parser not available'
    return nil
  end

  local tree = parser:parse()[1]
  if not tree then
    utils.notify_warn 'Failed to parse syntax tree'
    return nil
  end

  local root = tree:root()

  -- Get node at cursor position
  local node = root:named_descendant_for_range(cursor_row, 0, cursor_row, 0)
  if not node then
    utils.notify_warn 'No node found at cursor position'
    return nil
  end

  -- Walk up the tree to collect test names
  local test_names = {}
  local found_test = false

  while node do
    if node:type() == constants.TEST_NODE_TYPES.CALL_EXPRESSION then
      local func_node = node:field('function')[1]
      if func_node then
        local func_name = vim.treesitter.get_node_text(func_node, bufnr)

        if is_test_function(func_name) then
          local args_node = node:field('arguments')[1]
          if args_node and args_node:named_child_count() > 0 then
            local string_node = args_node:named_child(0)
            local test_name = get_string_content(string_node, bufnr)

            if test_name then
              -- Insert at beginning to maintain correct order
              table.insert(test_names, 1, test_name)

              if is_test_block(func_name) then
                found_test = true
              end
            end
          end
        end
      end
    end

    node = node:parent()
  end

  if not found_test or #test_names == 0 then
    utils.notify_warn 'No test block found under cursor'
    return nil
  end

  -- Escape special characters for Jest regex matching
  local escaped_names = {}
  for _, name in ipairs(test_names) do
    table.insert(escaped_names, utils.escape_pattern(name))
  end

  return table.concat(escaped_names, ' ')
end

--- Collect all test blocks in the file with their line numbers and full names
---@param bufnr number|nil Buffer number (nil for current buffer)
---@return table[] Array of test info: { line, name, full_name, type }
function M.collect_all_tests(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'typescript')
  if not ok then
    return {}
  end

  local tree = parser:parse()[1]
  if not tree then
    return {}
  end

  local root = tree:root()
  local tests = {}

  -- Recursive function to traverse the tree and collect test blocks
  local function traverse(node, parent_names)
    parent_names = parent_names or {}

    if node:type() == constants.TEST_NODE_TYPES.CALL_EXPRESSION then
      local func_node = node:field('function')[1]
      if func_node then
        local func_name = vim.treesitter.get_node_text(func_node, bufnr)

        if is_test_function(func_name) then
          local args_node = node:field('arguments')[1]
          if args_node and args_node:named_child_count() > 0 then
            local string_node = args_node:named_child(0)
            local test_name = get_string_content(string_node, bufnr)

            if test_name then
              local start_row, _, _, _ = node:range()
              local full_name_parts = vim.list_extend({}, parent_names)
              table.insert(full_name_parts, test_name)

              table.insert(tests, {
                line = start_row,
                name = test_name,
                full_name = table.concat(full_name_parts, ' '),
                type = func_name,
              })

              -- If it's a describe, traverse its children with updated parent names
              if func_name == constants.TEST_FUNCTION_NAMES.DESCRIBE then
                for child in node:iter_children() do
                  traverse(child, full_name_parts)
                end
              end
            end
          end
        end
      end
    end

    -- Traverse all children for non-describe nodes
    for child in node:iter_children() do
      if
        node:type() ~= constants.TEST_NODE_TYPES.CALL_EXPRESSION
        or vim.treesitter.get_node_text(node:field('function')[1] or node, bufnr) ~= constants.TEST_FUNCTION_NAMES.DESCRIBE
      then
        traverse(child, parent_names)
      end
    end
  end

  traverse(root)
  return tests
end

--- Extract test pattern from Jest arguments
---@param args string Jest command arguments
---@return string|nil Test pattern if found
function M.extract_test_pattern(args)
  return args:match("-t%s+'([^']+)'") or args:match('-t%s+"([^"]+)"')
end

--- Collect test lines that match a specific pattern
---@param bufnr number Buffer number
---@param pattern string|nil Test pattern to match (nil for all tests)
---@return number[] Array of line numbers
function M.collect_test_lines_for_pattern(bufnr, pattern)
  local all_tests = M.collect_all_tests(bufnr)
  local test_lines = {}

  for _, test in ipairs(all_tests) do
    if is_test_block(test.type) then
      if pattern then
        if test.full_name:find(pattern, 1, true) then
          table.insert(test_lines, test.line)
        end
      else
        table.insert(test_lines, test.line)
      end
    end
  end

  return test_lines
end

return M
