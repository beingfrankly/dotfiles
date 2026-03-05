-- Jest test runner plugin
-- Provides commands and keybindings to run Jest tests

local M = {}

-- Configuration
M.config = {
  jest_cmd = 'jest',
  split_direction = 'horizontal', -- 'horizontal' or 'vertical'
  split_size = 15, -- height for horizontal, width for vertical
  focus_after_run = false, -- focus the test output window after running
  auto_detect_config = true, -- auto-detect jest.config.ts/js
  use_virtual_text = true, -- show results as virtual text inline
  show_split_on_error = true, -- show split window when tests fail
}

-- Namespace for virtual text extmarks
local ns_id = vim.api.nvim_create_namespace 'jest_runner'

-- Spinner frames for running tests
local spinner_frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }

-- State management
M.state = {
  last_test_cmd = nil,
  test_buf = nil,
  test_win = nil,
  test_job = nil,
  spinner_timer = nil,
  spinner_frame = 1,
  virtual_text_marks = {}, -- Track extmarks for cleanup
}

-- Helper function to get the current file path relative to project root
local function get_relative_path()
  local Path = require 'plenary.path'
  local filepath = Path:new(vim.fn.expand '%:p')
  local cwd = Path:new(vim.fn.getcwd())
  return filepath:make_relative(cwd.filename)
end

-- Helper function to check if current file is a test file
local function is_test_file()
  local filename = vim.fn.expand '%:t'
  return filename:match '%.spec%.ts$' or filename:match '%.spec%.js$' or filename:match '%.test%.ts$' or filename:match '%.test%.js$'
end

-- Find the nearest jest.config file by walking up from the current file
local function find_jest_config()
  local Path = require 'plenary.path'
  local current_file = Path:new(vim.fn.expand '%:p')
  local root = Path:new(vim.fn.getcwd())

  -- Walk up from current file directory to project root
  for _, dir in ipairs(current_file:parents()) do
    local dir_path = Path:new(dir)

    -- Stop if we've gone above the project root
    if not dir_path:is_absolute() or not vim.startswith(dir_path.filename, root.filename) then
      break
    end

    -- Check for various config file names
    for _, config_name in ipairs { 'jest.config.ts', 'jest.config.js', 'jest.config.mjs', 'jest.config.cjs', 'jest.config.json' } do
      local config_path = dir_path / config_name
      if config_path:exists() then
        return config_path:make_relative(root.filename)
      end
    end
  end

  return nil
end

-- ============================================================================
-- Virtual Text Helpers
-- ============================================================================

-- Clear all virtual text and diagnostics in current buffer
local function clear_virtual_text(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  vim.diagnostic.set(ns_id, bufnr, {}, {}) -- Clear diagnostics
  M.state.virtual_text_marks = {}
end

-- Set virtual text on a specific line
local function set_virtual_text(bufnr, line, text, hl_group)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Clear existing mark on this line
  local existing_marks = vim.api.nvim_buf_get_extmarks(bufnr, ns_id, { line, 0 }, { line, -1 }, {})
  for _, mark in ipairs(existing_marks) do
    vim.api.nvim_buf_del_extmark(bufnr, ns_id, mark[1])
  end

  -- Set new virtual text
  local mark_id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, 0, {
    virt_text = { { text, hl_group } },
    virt_text_pos = 'eol',
  })

  M.state.virtual_text_marks[line] = mark_id
  return mark_id
end

-- Start spinner animation on specific lines
local function start_spinner(bufnr, lines)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Stop existing timer
  if M.state.spinner_timer then
    M.state.spinner_timer:stop()
    M.state.spinner_timer:close()
  end

  -- Create new timer for spinner animation
  M.state.spinner_timer = vim.loop.new_timer()
  M.state.spinner_frame = 1

  M.state.spinner_timer:start(
    0,
    100, -- Update every 100ms
    vim.schedule_wrap(function()
      if not vim.api.nvim_buf_is_valid(bufnr) then
        if M.state.spinner_timer then
          M.state.spinner_timer:stop()
          M.state.spinner_timer:close()
          M.state.spinner_timer = nil
        end
        return
      end

      local frame = spinner_frames[M.state.spinner_frame]
      for _, line in ipairs(lines) do
        set_virtual_text(bufnr, line, '  ' .. frame .. ' running...', 'Comment')
      end

      M.state.spinner_frame = M.state.spinner_frame + 1
      if M.state.spinner_frame > #spinner_frames then
        M.state.spinner_frame = 1
      end
    end)
  )
end

-- Stop spinner animation
local function stop_spinner()
  if M.state.spinner_timer then
    M.state.spinner_timer:stop()
    M.state.spinner_timer:close()
    M.state.spinner_timer = nil
  end
end

-- Helper to escape special regex characters for Jest pattern matching
local function escape_pattern(str)
  local result = str:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1')
  return result
end

-- Helper to extract string content from a Tree-sitter node
local function get_string_content(node, bufnr)
  if not node then
    return nil
  end

  local text = vim.treesitter.get_node_text(node, bufnr)
  if not text then
    return nil
  end

  -- Remove surrounding quotes (single, double, or backticks)
  return text:match "^['\"`](.+)['\"`]$" or text
end

-- Use Tree-sitter to find test blocks and build pattern
local function build_test_name_pattern()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor_pos[1] - 1 -- Convert to 0-indexed

  -- Get Tree-sitter parser
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'typescript')
  if not ok then
    vim.notify('Tree-sitter parser not available', vim.log.levels.WARN)
    return nil
  end

  local tree = parser:parse()[1]
  if not tree then
    vim.notify('Failed to parse syntax tree', vim.log.levels.WARN)
    return nil
  end

  local root = tree:root()

  -- Get node at cursor position
  local node = root:named_descendant_for_range(cursor_row, 0, cursor_row, 0)
  if not node then
    vim.notify('No node found at cursor position', vim.log.levels.WARN)
    return nil
  end

  -- Walk up the tree to collect test names
  local test_names = {}
  local found_test = false

  while node do
    if node:type() == 'call_expression' then
      -- Get the function being called
      local func_node = node:field('function')[1]
      if func_node then
        local func_name = vim.treesitter.get_node_text(func_node, bufnr)

        -- Check if it's a test function (describe, it, or test)
        if func_name == 'describe' or func_name == 'it' or func_name == 'test' then
          -- Get the arguments
          local args_node = node:field('arguments')[1]
          if args_node and args_node:named_child_count() > 0 then
            -- First argument should be the test name (string)
            local string_node = args_node:named_child(0)
            local test_name = get_string_content(string_node, bufnr)

            if test_name then
              -- Insert at beginning to maintain correct order (innermost first becomes last)
              table.insert(test_names, 1, test_name)

              -- Mark that we found at least one test block
              if func_name == 'it' or func_name == 'test' then
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
    vim.notify('No test block found under cursor', vim.log.levels.WARN)
    return nil
  end

  -- Escape special characters for Jest regex matching
  local escaped_names = {}
  for _, name in ipairs(test_names) do
    table.insert(escaped_names, escape_pattern(name))
  end

  return table.concat(escaped_names, ' ')
end

-- ============================================================================
-- Tree-sitter Test Collection
-- ============================================================================

-- Collect all test blocks in the file with their line numbers and full names
local function collect_all_tests(bufnr)
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

    if node:type() == 'call_expression' then
      local func_node = node:field('function')[1]
      if func_node then
        local func_name = vim.treesitter.get_node_text(func_node, bufnr)

        if func_name == 'describe' or func_name == 'it' or func_name == 'test' then
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
              if func_name == 'describe' then
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
      if node:type() ~= 'call_expression' or vim.treesitter.get_node_text(node:field('function')[1] or node, bufnr) ~= 'describe' then
        traverse(child, parent_names)
      end
    end
  end

  traverse(root)
  return tests
end

-- ============================================================================
-- Jest JSON Output Parsing
-- ============================================================================

-- Parse Jest JSON output and map results to tests
local function parse_jest_results(json_output)
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
            status = assertion.status, -- 'passed', 'failed', 'pending', 'skipped'
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

-- Apply test results as virtual text
local function apply_test_results(bufnr, test_results)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Stop spinner
  stop_spinner()

  -- Collect all tests in the file
  local all_tests = collect_all_tests(bufnr)

  -- Build diagnostics list for failed tests
  local diagnostics = {}

  -- Match results to line numbers and set virtual text
  for _, test in ipairs(all_tests) do
    local result = test_results[test.full_name]

    -- Only show virtual text for tests that actually ran (passed or failed)
    -- Skip pending/skipped tests (those that didn't match the filter)
    if result and result.status ~= 'pending' and result.status ~= 'skipped' then
      local icon, hl_group

      if result.status == 'passed' then
        icon = '✓'
        hl_group = 'DiagnosticOk'
      elseif result.status == 'failed' then
        icon = '✗'
        hl_group = 'DiagnosticError'

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
        -- Unknown status
        icon = '?'
        hl_group = 'Comment'
      end

      -- Simple virtual text: just the icon
      local text = '  ' .. icon
      set_virtual_text(bufnr, test.line, text, hl_group)
    end
  end

  -- Set LSP diagnostics for failed tests
  vim.diagnostic.set(ns_id, bufnr, diagnostics, {})
end

-- Create or reuse test output window
local function get_or_create_test_window()
  -- Check if window still exists and is valid
  if M.state.test_win and vim.api.nvim_win_is_valid(M.state.test_win) then
    return M.state.test_win, M.state.test_buf
  end

  -- Check if buffer still exists (window was closed but buffer remains)
  if M.state.test_buf and vim.api.nvim_buf_is_valid(M.state.test_buf) then
    -- Reuse existing buffer
    local direction = M.config.split_direction == 'vertical' and 'vnew' or 'new'
    vim.cmd(direction)
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, M.state.test_buf)

    -- Set window size
    if M.config.split_direction == 'vertical' then
      vim.api.nvim_win_set_width(win, M.config.split_size)
    else
      vim.api.nvim_win_set_height(win, M.config.split_size)
    end

    M.state.test_win = win
    return win, M.state.test_buf
  end

  -- Create new split and buffer
  local direction = M.config.split_direction == 'vertical' and 'vnew' or 'new'
  vim.cmd(direction)

  -- Get the new window and buffer
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)

  -- Set window size
  if M.config.split_direction == 'vertical' then
    vim.api.nvim_win_set_width(win, M.config.split_size)
  else
    vim.api.nvim_win_set_height(win, M.config.split_size)
  end

  -- Configure buffer
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe') -- Changed from 'hide' to 'wipe' to auto-delete
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_name(buf, 'Jest Output')

  -- Add keymaps to close the window
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', { noremap = true, silent = true })

  -- Store references
  M.state.test_win = win
  M.state.test_buf = buf

  return win, buf
end

-- Helper to append line to output buffer
local function append_to_output(buf, line)
  if line and line ~= '' then
    vim.schedule(function()
      local line_count = vim.api.nvim_buf_line_count(buf)
      vim.api.nvim_buf_set_lines(buf, line_count, line_count, false, { line })
    end)
  end
end

-- Helper to try parsing accumulated JSON output
local function try_parse_and_apply_results(json_lines, source_bufnr)
  local full_json = table.concat(json_lines, '\n')

  -- Try to find a complete JSON object
  -- Jest outputs JSON as a single line or multiline object
  local json_start = full_json:find('{')
  if not json_start then
    return nil
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
    return nil -- Incomplete JSON
  end

  -- Extract and parse JSON
  local json_str = full_json:sub(json_start, json_end)
  local test_results = parse_jest_results(json_str)

  if test_results then
    stop_spinner()
    apply_test_results(source_bufnr, test_results)
    return json_end -- Return position where JSON ended
  end

  return nil
end

-- Run a Jest command
local function run_jest(args, is_watch_mode)
  if not is_test_file() then
    vim.notify('Current file is not a test file', vim.log.levels.WARN)
    return
  end

  local Job = require 'plenary.job'
  local source_bufnr = vim.api.nvim_get_current_buf()

  -- Build command
  local cmd = M.config.jest_cmd

  -- Add config file if auto-detection is enabled
  if M.config.auto_detect_config then
    local config_file = find_jest_config()
    if config_file then
      cmd = cmd .. ' --config ' .. config_file
    end
  end

  -- Add JSON output flag for parsing results
  cmd = cmd .. ' --json ' .. args

  -- Save command for re-running
  M.state.last_test_cmd = cmd

  -- Use current working directory (should be monorepo root)
  local jest_cwd = vim.fn.getcwd()

  -- Clear previous virtual text
  clear_virtual_text(source_bufnr)

  -- If using virtual text, start spinner only on tests that will run
  if M.config.use_virtual_text then
    local all_tests = collect_all_tests(source_bufnr)
    local test_lines = {}

    -- Check if we're running a specific test with -t flag
    local test_pattern = args:match("-t%s+'([^']+)'") or args:match('-t%s+"([^"]+)"')

    for _, test in ipairs(all_tests) do
      if test.type == 'it' or test.type == 'test' then
        -- If there's a test pattern, only show spinner on matching tests
        if test_pattern then
          -- Check if this test's full name matches the pattern
          if test.full_name:find(test_pattern, 1, true) then
            table.insert(test_lines, test.line)
          end
        else
          -- No pattern, show on all tests
          table.insert(test_lines, test.line)
        end
      end
    end

    if #test_lines > 0 then
      start_spinner(source_bufnr, test_lines)
    end
  end

  -- Kill existing job if running
  if M.state.test_job then
    M.state.test_job:shutdown()
  end

  -- Accumulate output for JSON parsing
  local json_output = {}
  local stderr_output = {}
  local last_parsed_pos = 0
  local has_shown_results = false
  local spinner_started = false

  -- Determine shell to use
  local shell = vim.o.shell
  local shell_flag = vim.o.shell:match 'cmd.exe$' and '/c' or '-c'

  -- Run the command using plenary.job with shell
  M.state.test_job = Job:new {
    command = shell,
    args = { shell_flag, cmd },
    cwd = jest_cwd, -- Use directory containing jest.config
    on_stdout = vim.schedule_wrap(function(_, line)
      if not line then return end -- Guard against nil

      table.insert(json_output, line)

      -- In watch mode, try to parse JSON incrementally
      if is_watch_mode and M.config.use_virtual_text then
        local parsed_end = try_parse_and_apply_results(json_output, source_bufnr)
        if parsed_end then
          -- Clear processed JSON to avoid re-parsing
          json_output = {}
          last_parsed_pos = 0
          has_shown_results = true
          spinner_started = false
        end
      end
    end),
    on_stderr = vim.schedule_wrap(function(_, line)
      if not line then return end -- Guard against nil

      table.insert(stderr_output, line)

      -- In watch mode, detect when Jest starts running tests
      if is_watch_mode and has_shown_results and not spinner_started then
        -- Jest outputs patterns like "PASS", "FAIL", "Determining test suites"
        -- When we see these after showing results, tests are running again
        if line:match('Determining test suites') or line:match('RUNS') then
          spinner_started = true
          -- Restart spinner for the tests that will run
          if M.config.use_virtual_text then
            local all_tests = collect_all_tests(source_bufnr)
            local test_lines = {}

            -- Extract test pattern from args
            local test_pattern = args:match("-t%s+'([^']+)'") or args:match('-t%s+"([^"]+)"')

            for _, test in ipairs(all_tests) do
              if test.type == 'it' or test.type == 'test' then
                if test_pattern then
                  if test.full_name:find(test_pattern, 1, true) then
                    table.insert(test_lines, test.line)
                  end
                else
                  table.insert(test_lines, test.line)
                end
              end
            end

            if #test_lines > 0 then
              start_spinner(source_bufnr, test_lines)
            end
          end
        end
      end
    end),
    on_exit = vim.schedule_wrap(function(j, exit_code)
      stop_spinner()

      -- Only clean up if not in watch mode
      if not is_watch_mode then
        -- Try to parse JSON results
        local full_json = table.concat(json_output, '\n')
        local test_results = parse_jest_results(full_json)

        if test_results and M.config.use_virtual_text then
          -- Apply virtual text results
          apply_test_results(source_bufnr, test_results)

          -- Show split window only on errors if configured
          local has_failures = false
          for _, result in pairs(test_results) do
            if result.status == 'failed' then
              has_failures = true
              break
            end
          end

          if has_failures and M.config.show_split_on_error then
            -- Show split with error details
            local win, buf = get_or_create_test_window()
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

            local output = {
              '─────────────────────────────────────',
              'Jest Test Results (Failures)',
              '─────────────────────────────────────',
              '',
            }

            -- Add stderr output (contains formatted errors)
            vim.list_extend(output, stderr_output)

            vim.api.nvim_buf_set_lines(buf, 0, 0, false, output)

            if not M.config.focus_after_run then
              vim.cmd 'wincmd p'
            end
          end
        else
          -- Fallback: show split window with output if JSON parsing failed
          local win, buf = get_or_create_test_window()
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

          local output = {
            '─────────────────────────────────────',
            'Jest Test Output',
            '─────────────────────────────────────',
            '',
          }
          vim.list_extend(output, json_output)
          vim.list_extend(output, stderr_output)

          vim.api.nvim_buf_set_lines(buf, 0, 0, false, output)

          if not M.config.focus_after_run then
            vim.cmd 'wincmd p'
          end
        end

        M.state.test_job = nil
      end
    end),
  }

  M.state.test_job:start()
end

-- Command implementations
function M.run_nearest_test()
  local test_name = build_test_name_pattern()
  if not test_name then
    return
  end

  local filepath = get_relative_path()
  local args = string.format("%s -t '%s' --watch", filepath, test_name)

  vim.notify('Running test in watch mode: ' .. test_name, vim.log.levels.INFO)
  run_jest(args, true) -- true = watch mode
end

function M.run_file()
  local filepath = get_relative_path()
  vim.notify('Running all tests in file', vim.log.levels.INFO)
  run_jest(filepath, false) -- false = not watch mode
end

function M.run_file_watch()
  local filepath = get_relative_path()
  vim.notify('Running tests in watch mode', vim.log.levels.INFO)
  run_jest(filepath .. ' --watch', true) -- true = watch mode
end

function M.run_with_coverage()
  local filepath = get_relative_path()
  vim.notify('Running tests with coverage', vim.log.levels.INFO)
  run_jest(filepath .. ' --coverage', false)
end

function M.run_debug()
  local filepath = get_relative_path()
  vim.notify('Running tests in debug mode', vim.log.levels.INFO)
  vim.notify('Attach debugger to process on port 9229', vim.log.levels.INFO)
  run_jest('--inspect-brk --runInBand ' .. filepath, false)
end

function M.run_last()
  if not M.state.last_test_cmd then
    vim.notify('No previous test run', vim.log.levels.WARN)
    return
  end

  vim.notify('Re-running last test', vim.log.levels.INFO)
  -- Detect if last command had --watch
  local has_watch = M.state.last_test_cmd:find('--watch') ~= nil
  run_jest(M.state.last_test_cmd:gsub('^' .. M.config.jest_cmd .. ' ', ''), has_watch)
end

function M.stop_tests()
  if M.state.test_job then
    M.state.test_job:shutdown()
    stop_spinner() -- Stop spinner when stopping tests
    clear_virtual_text() -- Clear any virtual text
    vim.notify('Stopped running tests', vim.log.levels.INFO)
    M.state.test_job = nil
  else
    vim.notify('No tests running', vim.log.levels.WARN)
  end
end

function M.toggle_output()
  if M.state.test_win and vim.api.nvim_win_is_valid(M.state.test_win) then
    vim.api.nvim_win_close(M.state.test_win, true)
    M.state.test_win = nil
  else
    get_or_create_test_window()
  end
end

-- Setup function
function M.setup(opts)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  -- Command definitions: each entry defines both a user command and keybinding
  local commands = {
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

  -- Register all commands and keybindings
  for _, cmd in ipairs(commands) do
    -- Create user command
    vim.api.nvim_create_user_command(cmd.name, cmd.fn, { desc = cmd.desc })

    -- Create keybinding
    vim.keymap.set('n', '<leader>' .. cmd.key, cmd.fn, {
      desc = '[T]est: ' .. cmd.key_desc,
    })
  end

  vim.notify('Jest test runner loaded', vim.log.levels.INFO)
end

return M
