-- java-extras.lua
-- Enhanced Java LSP features for jdtls

---@class Logger
---@field log_file string
local Logger = {}
Logger.__index = Logger

---@return Logger
function Logger.new()
  local self = setmetatable({}, Logger)
  self.log_file = vim.fn.stdpath 'cache' .. '/java-extras-debug.log'
  return self
end

---@param level string
---@param module string
---@param message string
---@param data? any
function Logger:write(level, module, message, data)
  if not vim.g.java_extras_debug then
    return
  end

  local timestamp = os.date '%Y-%m-%d %H:%M:%S'
  local log_entry = string.format('[%s] [%s] [%s] %s\n', timestamp, level, module, message)

  if data ~= nil then
    log_entry = log_entry .. vim.inspect(data) .. '\n'
  end

  vim.uv.fs_open(self.log_file, 'a', 438, function(err, fd)
    if err or not fd then
      return
    end

    vim.uv.fs_write(fd, log_entry, -1, function()
      vim.uv.fs_close(fd)
    end)
  end)
end

function Logger:debug(module, message, data)
  self:write('DEBUG', module, message, data)
end

function Logger:info(module, message, data)
  self:write('INFO', module, message, data)
end

function Logger:warn(module, message, data)
  self:write('WARN', module, message, data)
end

function Logger:error(module, message, data)
  self:write('ERROR', module, message, data)
end

local log = Logger.new()

---Get the jdtls client for the current buffer
---@return vim.lsp.Client|nil
local function get_jdtls_client()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients { bufnr = bufnr, name = 'jdtls' }

  if #clients == 0 then
    log:warn('get-client', 'No jdtls client found for current buffer')
    return nil
  end

  log:debug('get-client', 'Found jdtls client', { id = clients[1].id, name = clients[1].name })
  return clients[1]
end

---Extract class body from Java source lines
---@param lines string[]
---@return string[]
local function extract_class_body(lines)
  local result = {}
  local in_class = false
  local brace_count = 0
  local class_line = ''

  for _, line in ipairs(lines) do
    -- Find class declaration
    if not in_class and (line:match '^%s*public%s+class' or line:match '^%s*class' or line:match '^%s*public%s+interface' or line:match '^%s*interface') then
      in_class = true
      class_line = line
      -- Count braces in the class declaration line
      for char in line:gmatch '.' do
        if char == '{' then
          brace_count = brace_count + 1
        elseif char == '}' then
          brace_count = brace_count - 1
        end
      end
      table.insert(result, line)
    elseif in_class then
      table.insert(result, line)
      -- Count braces to find end of class
      for char in line:gmatch '.' do
        if char == '{' then
          brace_count = brace_count + 1
        elseif char == '}' then
          brace_count = brace_count - 1
        end
      end

      -- If we've closed all braces, we're done
      if brace_count == 0 then
        break
      end
    end
  end

  log:debug('extract-class-body', 'Extracted class body', { lines = #result, brace_count = brace_count })
  return result
end

---Get class definition from source file
---@param bufnr integer
---@param position table
---@param client vim.lsp.Client
---@param callback fun(lines: string[]?, lang: string?)
local function get_class_definition(bufnr, position, client, callback)
  log:info('get-class-definition', 'Requesting definition for position', position)

  client.request('textDocument/definition', position, function(err, result)
    if err then
      log:error('get-class-definition', 'Definition request failed', err)
      callback(nil, nil)
      return
    end

    if not result or (vim.tbl_islist(result) and #result == 0) then
      log:warn('get-class-definition', 'No definition found')
      callback(nil, nil)
      return
    end

    -- Handle both single location and array of locations
    local definition = vim.tbl_islist(result) and result[1] or result
    log:debug('get-class-definition', 'Got definition', definition)

    -- Get URI and range
    local uri = definition.uri or definition.targetUri
    local range = definition.range or definition.targetRange

    if not uri or not range then
      log:error('get-class-definition', 'Definition missing uri or range')
      callback(nil, nil)
      return
    end

    -- Convert URI to buffer number
    local target_bufnr = vim.uri_to_bufnr(uri)
    log:debug('get-class-definition', 'Target buffer', { bufnr = target_bufnr, uri = uri })

    -- Ensure buffer is loaded
    if not vim.api.nvim_buf_is_loaded(target_bufnr) then
      vim.fn.bufload(target_bufnr)
      log:debug('get-class-definition', 'Loaded buffer', { bufnr = target_bufnr })
    end

    -- Get the lines from the buffer
    local start_line = range.start.line
    local end_line = range['end'].line

    -- For Java classes, we need to read more lines to get the full class body
    -- Read from the start line to a reasonable amount beyond to capture the full class
    local buffer_line_count = vim.api.nvim_buf_line_count(target_bufnr)
    local read_end = math.min(start_line + 200, buffer_line_count) -- Read up to 200 lines or end of file

    local lines = vim.api.nvim_buf_get_lines(target_bufnr, start_line, read_end, false)
    log:debug('get-class-definition', 'Read lines from buffer', { start = start_line, end_read = read_end, count = #lines })

    -- Extract just the class body
    local class_lines = extract_class_body(lines)

    if #class_lines > 0 then
      log:info('get-class-definition', 'Successfully extracted class definition', { lines = #class_lines })
      callback(class_lines, 'java')
    else
      log:warn('get-class-definition', 'No class body extracted')
      callback(nil, nil)
    end
  end, bufnr)
end

---Show enhanced hover with full class definition
local function show_class_hover()
  log:info('show-class-hover', 'Starting enhanced hover')

  local client = get_jdtls_client()
  if not client then
    log:error('show-class-hover', 'No jdtls client available')
    vim.notify('No jdtls client found', vim.log.levels.ERROR)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)

  log:debug('show-class-hover', 'Getting class definition', params)

  get_class_definition(bufnr, params, client, function(class_def, lang)
    if class_def and #class_def > 0 then
      log:info('show-class-hover', 'Displaying class definition', { lines = #class_def })

      -- Display without markdown wrapper
      local float_bufnr, winnr = vim.lsp.util.open_floating_preview(class_def, lang or 'java', {
        border = 'rounded',
        max_width = 120,
        max_height = 40,
        focusable = true,
        focus = false,
      })

      if float_bufnr and vim.api.nvim_buf_is_valid(float_bufnr) then
        vim.bo[float_bufnr].filetype = lang or 'java'
        log:debug('show-class-hover', 'Created hover window', { bufnr = float_bufnr, winnr = winnr })
      end
    else
      log:warn('show-class-hover', 'No class definition to display, falling back to standard hover')
      -- Fall back to standard LSP hover
      vim.lsp.buf.hover()
    end
  end)
end

---Setup keymaps and commands
local function setup()
  log:info('setup', 'Setting up Java extras')

  -- Create commands
  vim.api.nvim_create_user_command('JavaShowLog', function()
    local log_file = vim.fn.stdpath 'cache' .. '/java-extras-debug.log'
    if vim.fn.filereadable(log_file) == 1 then
      vim.cmd('tabnew ' .. log_file)
    else
      vim.notify('No log file found at: ' .. log_file, vim.log.levels.WARN)
    end
  end, { desc = 'Show Java extras debug log' })

  vim.api.nvim_create_user_command('JavaClearLog', function()
    local log_file = vim.fn.stdpath 'cache' .. '/java-extras-debug.log'
    vim.fn.writefile({}, log_file)
    vim.notify('Java extras log cleared', vim.log.levels.INFO)
  end, { desc = 'Clear Java extras debug log' })

  -- Disabled: the custom K override was based on textDocument/definition + class-body extraction
  -- and shadowed jdtls's textDocument/hover, leaving methods/fields/locals/parameters/primitives
  -- without a proper type+Javadoc popup. Re-enable once show_class_hover is reworked to use
  -- textDocument/hover (or expose it under a separate keymap).
  --
  -- -- Setup autocmd for Java files
  -- vim.api.nvim_create_autocmd('FileType', {
  --   pattern = 'java',
  --   callback = function(ev)
  --     local bufnr = ev.buf
  --     log:info('filetype-autocmd', 'Setting up Java buffer', { bufnr = bufnr })
  --
  --     -- Override K mapping for enhanced hover
  --     vim.keymap.set('n', 'K', show_class_hover, {
  --       buffer = bufnr,
  --       desc = 'Show enhanced Java hover',
  --       silent = true,
  --     })
  --
  --     log:debug('filetype-autocmd', 'Keymaps set for buffer', { bufnr = bufnr })
  --   end,
  -- })

  log:info('setup', 'Java extras setup complete')
end

-- Setup (the FileType autocmd inside setup() handles deferred loading)
vim.g.java_extras_debug = true
setup()
