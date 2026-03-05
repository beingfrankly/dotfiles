-- Enhanced TypeScript/JavaScript support using vtsls LSP server
-- Provides better type hovers, code organization commands, and file operations
-- Uses Neovim 0.11 APIs and integrates with Snacks.nvim

---@class VtslsExtras
local M = {}

---@class Logger
---@field log_file string Path to log file
---@field enabled boolean Whether logging is enabled
local Logger = {}
Logger.__index = Logger

--- Create new logger instance
---@return Logger
function Logger.new()
  local self = setmetatable({}, Logger)
  self.log_file = vim.fn.stdpath('cache') .. '/vtsls-debug.log'
  self.enabled = vim.g.vtsls_debug or false
  return self
end

--- Get current timestamp
---@return string ISO 8601 timestamp
local function get_timestamp()
  return os.date('%Y-%m-%d %H:%M:%S')
end

--- Write log entry to file (async)
---@param level string Log level (DEBUG, INFO, WARN, ERROR)
---@param module string Module name
---@param message string Log message
---@param data? table Optional data to inspect
function Logger:write(level, module, message, data)
  -- Check vim.g.vtsls_debug dynamically
  if not vim.g.vtsls_debug then
    return
  end

  local log_entry = string.format('[%s] [%s] [%s] %s', get_timestamp(), level, module, message)

  if data then
    log_entry = log_entry .. '\n' .. vim.inspect(data)
  end

  log_entry = log_entry .. '\n'

  -- Async file write using vim.uv
  vim.uv.fs_open(self.log_file, 'a', 438, function(err, fd)
    if err or not fd then
      return
    end
    vim.uv.fs_write(fd, log_entry, -1, function()
      vim.uv.fs_close(fd)
    end)
  end)
end

--- Log debug message
---@param module string Module name
---@param message string Log message
---@param data? table Optional data
function Logger:debug(module, message, data)
  self:write('DEBUG', module, message, data)
end

--- Log info message
---@param module string Module name
---@param message string Log message
---@param data? table Optional data
function Logger:info(module, message, data)
  self:write('INFO', module, message, data)
end

--- Log warning message
---@param module string Module name
---@param message string Log message
---@param data? table Optional data
function Logger:warn(module, message, data)
  self:write('WARN', module, message, data)
end

--- Log error message
---@param module string Module name
---@param message string Log message
---@param data? table Optional data
function Logger:error(module, message, data)
  self:write('ERROR', module, message, data)
end

--- Clear log file
function Logger:clear()
  vim.uv.fs_unlink(self.log_file)
  self:info('logger', 'Log file cleared')
end

--- Check file size and rotate if needed (5MB limit)
function Logger:check_rotation()
  vim.uv.fs_stat(self.log_file, function(err, stat)
    if not err and stat and stat.size > 5 * 1024 * 1024 then
      local backup = self.log_file .. '.old'
      vim.uv.fs_rename(self.log_file, backup)
    end
  end)
end

-- Create global logger instance
local log = Logger.new()

--- Get vtsls client for current buffer
---@return vim.lsp.Client|nil
local function get_vtsls_client()
  local clients = vim.lsp.get_clients({ bufnr = 0, name = 'vtsls' })
  if #clients > 0 then
    return clients[1]
  end
  return nil
end

--- Format TypeScript display parts into readable lines
---@param display_parts table[] Display parts from TypeScript
---@return string[] Formatted lines
local function format_display_parts(display_parts)
  if not display_parts or #display_parts == 0 then
    return {}
  end

  local lines = {}
  local current_line = ''

  for _, part in ipairs(display_parts) do
    local text = part.text or ''

    -- Split by newlines
    local text_lines = vim.split(text, '\n', { plain = true })

    for i, line in ipairs(text_lines) do
      if i == 1 then
        current_line = current_line .. line
      else
        table.insert(lines, current_line)
        current_line = line
      end
    end
  end

  -- Add remaining line
  if current_line ~= '' then
    table.insert(lines, current_line)
  end

  return lines
end

--- Extract type names referenced in a type definition (for intersections/unions)
---@param type_source string The type definition source
---@return table List of referenced type names
local function extract_type_references(type_source)
  local refs = {}
  -- Match type names in intersections (PersonalFields &) and unions (PersonalFields |)
  -- This is a simple pattern match - not a full parser
  for type_name in type_source:gmatch('([%u][%w_]+)%s*[&|]') do
    if not refs[type_name] then
      refs[type_name] = true
      log:debug('better-hover', 'Found type reference: ' .. type_name)
    end
  end
  return vim.tbl_keys(refs)
end

--- Extract fields from a type definition
---@param type_lines table Lines of type definition
---@return table List of field lines
local function extract_type_fields(type_lines)
  local fields = {}
  local in_body = false

  for _, line in ipairs(type_lines) do
    -- Skip the type declaration line
    if line:match('^%s*export%s+type') or line:match('^%s*type%s+') then
      -- Check if there's an opening brace on the same line
      if line:match('{') then
        in_body = true
        -- Extract any content after the opening brace
        local after_brace = line:match('{%s*(.*)$')
        if after_brace and after_brace ~= '' and not after_brace:match('^%s*$') then
          table.insert(fields, '  ' .. after_brace)
        end
      end
    elseif line:match('^%s*}%s*;?%s*$') then
      -- Closing brace, stop
      in_body = false
    elseif in_body then
      -- This is a field line
      table.insert(fields, line)
    end
  end

  return fields
end

--- Merge type intersection into a single flattened type
---@param type_name string The type name
---@param main_lines table Main type definition lines
---@param referenced_types table Map of type name to their definition lines
---@return table Merged type lines
local function merge_type_intersection(type_name, main_lines, referenced_types)
  local result = { 'export type ' .. type_name .. ' = {' }

  -- First, add fields from all referenced types (in order they appear)
  local main_source = table.concat(main_lines, '\n')
  local type_refs = extract_type_references(main_source)

  for _, ref_name in ipairs(type_refs) do
    if referenced_types[ref_name] then
      local ref_fields = extract_type_fields(referenced_types[ref_name])
      vim.list_extend(result, ref_fields)
    end
  end

  -- Then, add fields from the main type (the inline object part)
  local main_fields = extract_type_fields(main_lines)
  vim.list_extend(result, main_fields)

  -- Close the type
  table.insert(result, '};')

  return result
end

--- Get definition for a specific type by name
---@param bufnr number Buffer number
---@param type_name string The type name to search for
---@param client vim.lsp.Client LSP client
---@param callback function Callback with type source lines
local function get_type_by_name(bufnr, type_name, client, callback)
  -- Search for the type definition in the current buffer
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for i, line in ipairs(lines) do
    -- Look for: export type TypeName = or type TypeName =
    if line:match('^%s*export%s+type%s+' .. type_name .. '%s*=') or line:match('^%s*type%s+' .. type_name .. '%s*=') then
      log:debug('better-hover', 'Found type definition for ' .. type_name .. ' at line ' .. i)

      -- Find the end of the type definition (look for closing brace or semicolon)
      local start_idx = i - 1 -- 0-indexed
      local end_idx = start_idx
      local brace_count = 0
      local found_end = false

      for j = i, #lines do
        local check_line = lines[j]
        -- Count braces to find the end
        for c in check_line:gmatch('[{}]') do
          if c == '{' then
            brace_count = brace_count + 1
          else
            brace_count = brace_count - 1
          end
        end

        -- If we're back to 0 braces and we see a semicolon or closing brace, we're done
        if brace_count == 0 and (check_line:match('[};]%s*$') or j == #lines) then
          end_idx = j - 1
          found_end = true
          break
        end
      end

      if found_end then
        local type_lines = vim.api.nvim_buf_get_lines(bufnr, start_idx, end_idx + 1, false)
        vim.schedule(function()
          callback(type_lines)
        end)
        return
      end
    end
  end

  -- Type not found in current buffer
  vim.schedule(function()
    callback(nil)
  end)
end

--- Get type definition from source file with optional expansion
---@param bufnr number Buffer number
---@param position table LSP position params
---@param client vim.lsp.Client LSP client
---@param expand boolean Whether to expand referenced types
---@param callback function Callback with result
local function get_type_definition(bufnr, position, client, expand, callback)
  log:debug('better-hover', 'Requesting type definition', {
    bufnr = bufnr,
    position = position,
    expand = expand,
  })

  -- Use textDocument/definition to find where the type is declared
  client.request('textDocument/definition', position, function(err, result)
    if err then
      log:error('better-hover', 'Definition error', err)
      vim.schedule(function()
        callback(nil)
      end)
      return
    end

    if not result or vim.tbl_isempty(result) then
      log:warn('better-hover', 'Definition returned nil or empty')
      vim.schedule(function()
        callback(nil)
      end)
      return
    end

    -- Handle both single result and array of results
    local definition = result[1] or result
    if not definition.targetRange then
      log:warn('better-hover', 'No targetRange in definition result')
      vim.schedule(function()
        callback(nil)
      end)
      return
    end

    log:debug('better-hover', 'Definition result', definition)

    -- Get the file URI and range
    local uri = definition.uri or definition.targetUri
    local target_bufnr = vim.uri_to_bufnr(uri)

    -- Ensure buffer is loaded
    if not vim.api.nvim_buf_is_loaded(target_bufnr) then
      vim.fn.bufload(target_bufnr)
    end

    -- Extract the lines containing the type definition
    local start_line = definition.targetRange.start.line
    local end_line = definition.targetRange['end'].line

    -- Get just the lines in the targetRange (LSP already calculated the full range)
    -- Add 1 because nvim_buf_get_lines end is exclusive
    local lines = vim.api.nvim_buf_get_lines(target_bufnr, start_line, end_line + 1, false)

    if #lines == 0 then
      log:warn('better-hover', 'No lines extracted from type definition')
      vim.schedule(function()
        callback(nil)
      end)
      return
    end

    log:info('better-hover', string.format('Got %d lines from type definition', #lines))

    -- Detect the language for syntax highlighting
    local filepath = vim.uri_to_fname(uri)
    local lang = filepath:match('%.tsx?$') and 'typescript' or 'javascript'

    -- If expand is enabled, look for type references and merge them
    if expand then
      local type_source = table.concat(lines, '\n')
      local type_refs = extract_type_references(type_source)

      if #type_refs > 0 then
        log:info('better-hover', string.format('Found %d type references to expand', #type_refs))

        -- Fetch all referenced types
        local referenced_types = {}
        local refs_fetched = 0
        local total_refs = #type_refs

        for _, type_name in ipairs(type_refs) do
          get_type_by_name(target_bufnr, type_name, client, function(ref_lines)
            refs_fetched = refs_fetched + 1

            if ref_lines then
              referenced_types[type_name] = ref_lines
            end

            -- When all refs are fetched, merge and callback
            if refs_fetched == total_refs then
              -- Extract the original type name from the first line
              local original_type_name = lines[1]:match('type%s+([%w_]+)%s*=')
              if not original_type_name then
                -- Fallback to showing without merge
                vim.schedule(function()
                  callback(lines, lang)
                end)
                return
              end

              -- Merge the types
              local merged_lines = merge_type_intersection(original_type_name, lines, referenced_types)

              vim.schedule(function()
                callback(merged_lines, lang)
              end)
            end
          end)
        end
        return
      end
    end

    -- No expansion needed or no refs found
    vim.schedule(function()
      callback(lines, lang)
    end)
  end, bufnr)
end

--- Request TypeScript type information using LSP hover
---@param bufnr number Buffer number
---@param position table LSP position params
---@param client vim.lsp.Client LSP client
---@param callback function Callback with result
local function get_type_info(bufnr, position, client, callback)
  log:debug('better-hover', 'Requesting hover', {
    bufnr = bufnr,
    position = position,
  })

  -- Create timeout timer
  local timeout = 500 -- ms
  local timer = vim.uv.new_timer()
  local timed_out = false

  timer:start(timeout, 0, function()
    timed_out = true
    timer:close()
    log:warn('better-hover', 'Hover request timed out')
    vim.schedule(function()
      callback(nil)
    end)
  end)

  -- Use standard LSP hover request
  client.request('textDocument/hover', position, function(err, result)
    if timed_out then
      return
    end

    timer:close()

    if err then
      log:error('better-hover', 'Hover error', err)
      vim.schedule(function()
        callback(nil)
      end)
      return
    end

    if not result or not result.contents then
      log:warn('better-hover', 'Hover returned nil or no contents')
      vim.schedule(function()
        callback(nil)
      end)
      return
    end

    log:debug('better-hover', 'Hover result', result)

    -- Extract content from hover result
    local contents = result.contents
    local content_str = ''

    -- Handle different content formats
    if type(contents) == 'string' then
      -- Plain string
      content_str = contents
    elseif contents.kind == 'markdown' then
      -- Markdown content
      content_str = contents.value
    elseif contents.kind == 'plaintext' then
      -- Plain text content
      content_str = contents.value
    elseif type(contents) == 'table' and #contents > 0 then
      -- Array of MarkedString
      local parts = {}
      for _, item in ipairs(contents) do
        if type(item) == 'string' then
          table.insert(parts, item)
        elseif item.value then
          table.insert(parts, item.value)
        end
      end
      content_str = table.concat(parts, '\n')
    end

    if content_str ~= '' then
      -- Try to detect and annotate unexpanded types
      content_str = try_expand_type_aliases(content_str)

      local lines = vim.split(content_str, '\n')
      log:info('better-hover', string.format('Got %d lines from hover', #lines))
      vim.schedule(function()
        callback(lines)
      end)
    else
      log:warn('better-hover', 'No content in hover result')
      vim.schedule(function()
        callback(nil)
      end)
    end
  end, bufnr)
end

--- Show enhanced type hover with fallback to standard hover
local function show_type_hover()
  log:info('better-hover', 'Hover triggered')

  local client = get_vtsls_client()
  if not client then
    log:warn('better-hover', 'No vtsls client, using standard hover')
    vim.lsp.buf.hover()
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)

  -- Try to get type definition first (shows full source with expansion)
  get_type_definition(bufnr, params, client, true, function(type_def, lang)
    if type_def and #type_def > 0 then
      log:debug('better-hover', 'Showing type definition', { lines = #type_def })

      -- Create floating window without markdown wrapper for cleaner display
      local float_bufnr, winnr = vim.lsp.util.open_floating_preview(type_def, lang or 'typescript', {
        border = 'rounded',
        max_width = 120,
        max_height = 40,
        focusable = true,
        focus = false,
      })

      if float_bufnr and vim.api.nvim_buf_is_valid(float_bufnr) then
        -- Set the buffer filetype for syntax highlighting
        vim.bo[float_bufnr].filetype = lang or 'typescript'
        log:info('better-hover', 'Type definition window opened successfully')
      end
      return
    end

    -- Fallback to hover if definition didn't work
    log:info('better-hover', 'No type definition, trying hover')
    get_type_info(bufnr, params, client, function(type_info)
      if not type_info or #type_info == 0 then
        log:info('better-hover', 'No type info, falling back to standard hover')
        vim.lsp.buf.hover()
        return
      end

      log:debug('better-hover', 'Showing hover', { lines = #type_info })

      local float_bufnr, winnr = vim.lsp.util.open_floating_preview(type_info, 'markdown', {
        border = 'rounded',
        max_width = 120,
        max_height = 40,
        focusable = true,
        focus = false,
      })

      if float_bufnr and vim.api.nvim_buf_is_valid(float_bufnr) then
        vim.bo[float_bufnr].filetype = 'markdown'
        log:info('better-hover', 'Hover window opened successfully')
      end
    end)
  end)
end

--- Execute vtsls workspace command
---@param command string Command name
---@param args? table Command arguments
---@param callback? function Callback on completion
local function execute_vtsls_command(command, args, callback)
  local client = get_vtsls_client()
  if not client then
    vim.notify('vtsls LSP client not found', vim.log.levels.ERROR)
    log:error('vtsls-command', 'Client not found for command: ' .. command)
    return
  end

  log:info('vtsls-command', 'Executing command: ' .. command, args)

  local params = {
    command = command,
    arguments = args or {},
  }

  -- Show LSP progress (Neovim 0.11 feature)
  local progress_token = string.format('vtsls-%s-%s', command, os.time())

  client.request('workspace/executeCommand', params, function(err, result)
    if err then
      vim.notify(string.format('Command failed: %s', err.message), vim.log.levels.ERROR)
      log:error('vtsls-command', 'Command error: ' .. command, err)
      return
    end

    log:info('vtsls-command', 'Command completed: ' .. command, result)

    if callback then
      callback(result)
    end
  end, 0)
end

--- Organize imports in current file
local function organize_imports()
  local params = {
    command = '_typescript.organizeImports',
    arguments = {
      vim.api.nvim_buf_get_name(0),
    },
  }

  log:info('organize-imports', 'Starting organize imports')

  execute_vtsls_command(params.command, params.arguments, function()
    vim.notify('Imports organized', vim.log.levels.INFO)
    log:info('organize-imports', 'Completed successfully')
  end)
end

--- Remove unused imports from current file
local function remove_unused_imports()
  local params = {
    command = '_typescript.removeUnusedImports',
    arguments = {
      vim.api.nvim_buf_get_name(0),
    },
  }

  log:info('remove-unused', 'Starting remove unused imports')

  execute_vtsls_command(params.command, params.arguments, function()
    vim.notify('Unused imports removed', vim.log.levels.INFO)
    log:info('remove-unused', 'Completed successfully')
  end)
end

--- Apply all auto-fixes to current file
local function fix_all()
  local client = get_vtsls_client()
  if not client then
    vim.notify('vtsls client not found', vim.log.levels.ERROR)
    return
  end

  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
  params.context = {
    only = { 'source.fixAll.ts' },
    diagnostics = vim.diagnostic.get(0),
  }

  log:info('fix-all', 'Starting fix all')

  vim.lsp.buf.code_action({
    context = params.context,
    apply = true,
  })

  log:info('fix-all', 'Fix all requested')
  vim.notify('Applied all auto-fixes', vim.log.levels.INFO)
end

--- Rename current file and update imports
---@param new_name? string New filename (prompts if not provided)
local function rename_file(new_name)
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_name = vim.fn.fnamemodify(current_file, ':t')

  log:info('rename-file', 'Starting rename', { current = current_name })

  -- If no new name provided, prompt with Snacks
  if not new_name or new_name == '' then
    local ok, snacks = pcall(require, 'snacks')
    if not ok then
      vim.notify('Snacks.nvim not available', vim.log.levels.ERROR)
      log:error('rename-file', 'Snacks not loaded')
      return
    end

    snacks.input({
      prompt = 'Rename file to: ',
      default = current_name,
      completion = 'file',
    }, function(value)
      if value and value ~= '' then
        rename_file(value)
      else
        log:info('rename-file', 'Rename cancelled')
      end
    end)
    return
  end

  -- Construct new file path
  local dir = vim.fn.fnamemodify(current_file, ':h')
  local new_file = dir .. '/' .. new_name

  log:debug('rename-file', 'Renaming file', {
    from = current_file,
    to = new_file,
  })

  local params = {
    command = '_typescript.applyRenameFile',
    arguments = {
      {
        sourceUri = vim.uri_from_fname(current_file),
        targetUri = vim.uri_from_fname(new_file),
      },
    },
  }

  execute_vtsls_command(params.command, params.arguments, function(result)
    -- Apply workspace edit if returned
    if result then
      vim.lsp.util.apply_workspace_edit(result, 'utf-8')
    end

    -- Rename the actual file
    vim.fn.rename(current_file, new_file)

    -- Edit the new file
    vim.cmd('edit ' .. vim.fn.fnameescape(new_file))

    vim.notify(string.format('Renamed to %s', new_name), vim.log.levels.INFO)
    log:info('rename-file', 'Rename completed', { new_name = new_name })
  end)
end

--- Restart TypeScript language server
local function restart_server()
  log:info('restart-server', 'Restarting vtsls')

  local client = get_vtsls_client()
  if not client then
    vim.notify('vtsls client not found', vim.log.levels.ERROR)
    return
  end

  vim.notify('Restarting TypeScript server...', vim.log.levels.INFO)

  client.stop()

  vim.defer_fn(function()
    vim.cmd('edit') -- Trigger LSP attach
    vim.notify('TypeScript server restarted', vim.log.levels.INFO)
    log:info('restart-server', 'Restart completed')
  end, 1000)
end

--- Show log file in split
local function show_log()
  log:info('log-viewer', 'Opening log file')

  if vim.fn.filereadable(log.log_file) == 0 then
    vim.notify('No log file found', vim.log.levels.WARN)
    return
  end

  vim.cmd('split ' .. log.log_file)
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.swapfile = false
end

--- Tail log file (auto-updating split)
local function tail_log()
  show_log()

  -- Set up autocommand to reload on changes
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_create_autocmd('CursorHold', {
    buffer = bufnr,
    callback = function()
      vim.cmd('checktime')
      vim.cmd('normal! G') -- Jump to end
    end,
  })

  vim.bo[bufnr].autoread = true
  vim.notify('Tailing log file (CursorHold to refresh)', vim.log.levels.INFO)
end

--- Clear log file
local function clear_log()
  log:clear()
  vim.notify('Log file cleared', vim.log.levels.INFO)
end

--- Toggle debug mode
local function toggle_debug()
  vim.g.vtsls_debug = not vim.g.vtsls_debug

  local status = vim.g.vtsls_debug and 'enabled' or 'disabled'
  vim.notify('VTSLS debug ' .. status, vim.log.levels.INFO)
  log:info('debug-toggle', 'Debug mode ' .. status)
end

--- Show command picker with Snacks
local function show_commands()
  local ok, snacks = pcall(require, 'snacks')
  if not ok then
    vim.notify('Snacks.nvim not available', vim.log.levels.ERROR)
    return
  end

  local commands = {
    {
      text = 'Organize Imports',
      desc = 'Sort and organize imports',
      action = organize_imports,
    },
    {
      text = 'Remove Unused Imports',
      desc = 'Clean up unused imports',
      action = remove_unused_imports,
    },
    {
      text = 'Fix All',
      desc = 'Apply all auto-fixes',
      action = fix_all,
    },
    {
      text = 'Rename File',
      desc = 'Rename with import updates',
      action = rename_file,
    },
    {
      text = 'Restart TypeScript Server',
      desc = 'Restart tsserver',
      action = restart_server,
    },
    {
      text = 'Show Log',
      desc = 'View debug log',
      action = show_log,
    },
    {
      text = 'Tail Log',
      desc = 'Live tail debug log',
      action = tail_log,
    },
    {
      text = 'Clear Log',
      desc = 'Clear debug log file',
      action = clear_log,
    },
    {
      text = 'Toggle Debug',
      desc = 'Enable/disable logging',
      action = toggle_debug,
    },
  }

  snacks.picker.pick({
    prompt = 'VTSLS Commands',
    items = commands,
    format = function(item)
      return string.format('%-30s %s', item.text, item.desc)
    end,
    confirm = function(picker, item)
      if item and item.action then
        picker:close()
        item.action()
      end
    end,
  })
end

--- Setup function called by lazy.nvim
local function setup()
  log:info('setup', 'Initializing vtsls-extras plugin')
  log:check_rotation()

  -- Register vim commands
  vim.api.nvim_create_user_command('VtslsOrganizeImports', organize_imports, {
    desc = 'Organize imports',
  })

  vim.api.nvim_create_user_command('VtslsRemoveUnusedImports', remove_unused_imports, {
    desc = 'Remove unused imports',
  })

  vim.api.nvim_create_user_command('VtslsFixAll', fix_all, {
    desc = 'Apply all auto-fixes',
  })

  vim.api.nvim_create_user_command('VtslsRenameFile', function(opts)
    rename_file(opts.args)
  end, {
    desc = 'Rename file with import updates',
    nargs = '?',
    complete = 'file',
  })

  vim.api.nvim_create_user_command('VtslsRestartServer', restart_server, {
    desc = 'Restart TypeScript server',
  })

  vim.api.nvim_create_user_command('VtslsShowLog', show_log, {
    desc = 'Show debug log',
  })

  vim.api.nvim_create_user_command('VtslsTailLog', tail_log, {
    desc = 'Tail debug log',
  })

  vim.api.nvim_create_user_command('VtslsClearLog', clear_log, {
    desc = 'Clear debug log',
  })

  vim.api.nvim_create_user_command('VtslsToggleDebug', toggle_debug, {
    desc = 'Toggle debug mode',
  })

  vim.api.nvim_create_user_command('VtslsCommands', show_commands, {
    desc = 'Show VTSLS command picker',
  })

  -- Setup keybindings
  local function set_keymap(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
  end

  -- Code action keybindings
  set_keymap('n', '<leader>co', organize_imports, 'Organize imports')
  set_keymap('n', '<leader>cu', remove_unused_imports, 'Remove unused imports')
  set_keymap('n', '<leader>cf', fix_all, 'Fix all')
  set_keymap('n', '<leader>cr', rename_file, 'Rename file')
  set_keymap('n', '<leader>cR', restart_server, 'Restart TS server')
  set_keymap('n', '<leader>cv', show_commands, 'VTSLS commands')

  -- TypeScript keybindings
  set_keymap('n', '<leader>ctl', show_log, 'Show VTSLS log')
  set_keymap('n', '<leader>ctd', toggle_debug, 'Toggle debug')

  -- Setup which-key groups
  local ok, wk = pcall(require, 'which-key')
  if ok then
    wk.add({
      { '<leader>c', group = 'Code' },
      { '<leader>ct', group = 'TypeScript' },
    })
  end

  -- Setup LspAttach autocmd for K override
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('vtsls-extras-attach', { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == 'vtsls' then
        log:info('lsp-attach', 'vtsls attached to buffer ' .. args.buf)

        -- Override K for better hover
        vim.keymap.set('n', 'K', show_type_hover, {
          buffer = args.buf,
          desc = 'Show type definition (enhanced)',
          silent = true,
        })
      end
    end,
  })

  log:info('setup', 'Plugin initialized successfully')
end

return {
  name = 'vtsls-extras',
  dir = vim.fn.stdpath('config') .. '/lua/kickstart/plugins',
  ft = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
  config = function()
    -- Enable debug mode by default for initial testing
    vim.g.vtsls_debug = true

    -- Run setup
    setup()

    vim.notify('VTSLS extras loaded (debug mode enabled)', vim.log.levels.INFO)
  end,
}
