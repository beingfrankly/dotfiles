local M = {}

--- Opens a floating window in the center of the screen with a dimmed backdrop
--- @param opts table Optional configuration
---   - rows: number - explicit number of rows (takes precedence over height)
---   - cols: number - explicit number of columns (takes precedence over width)
---   - width: number or float (0-1 for percentage) - default 0.8
---   - height: number or float (0-1 for percentage) - default 0.8
---   - title: string - window title
---   - border: string - border style ('rounded', 'solid', 'double', 'none', etc.) - default 'rounded'
---   - relative: string - what the window position is relative to - default 'editor'
---   - backdrop_blend: number - transparency of backdrop (0-100) - default 50
--- @return number bufnr The buffer number
--- @return number winid The window ID
--- @return number backdrop_bufnr The backdrop buffer number
--- @return number backdrop_winid The backdrop window ID
function M.open_centered_float(opts)
  opts = opts or {}

  -- Get editor dimensions
  local width = vim.o.columns
  local height = vim.o.lines

  -- Create backdrop buffer
  local backdrop_bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[backdrop_bufnr].bufhidden = 'wipe'

  -- Create backdrop window (full screen)
  local backdrop_winid = vim.api.nvim_open_win(backdrop_bufnr, false, {
    relative = 'editor',
    width = width,
    height = height,
    row = 0,
    col = 0,
    style = 'minimal',
    focusable = false,
  })

  -- Make backdrop semi-transparent
  vim.wo[backdrop_winid].winblend = opts.backdrop_blend or 50
  vim.wo[backdrop_winid].winhighlight = 'Normal:Normal'

  -- Calculate window size
  local win_width, win_height

  -- Use cols if provided, otherwise use width
  if opts.cols then
    win_width = opts.cols
  else
    win_width = opts.width or 0.8
    -- Convert percentage to absolute value
    if win_width < 1 then
      win_width = math.floor(width * win_width)
    end
  end

  -- Use rows if provided, otherwise use height
  if opts.rows then
    win_height = opts.rows
  else
    win_height = opts.height or 0.8
    -- Convert percentage to absolute value
    if win_height < 1 then
      win_height = math.floor(height * win_height)
    end
  end

  -- Calculate starting position (centered)
  local row = math.floor((height - win_height) / 2)
  local col = math.floor((width - win_width) / 2)

  -- Create a new buffer
  local bufnr = vim.api.nvim_create_buf(false, true) -- not listed, scratch buffer

  -- Set buffer options
  vim.bo[bufnr].bufhidden = 'wipe'
  vim.bo[bufnr].filetype = 'searchreplace'

  -- Window configuration
  local win_opts = {
    relative = opts.relative or 'editor',
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = 'minimal',
    border = opts.border or 'rounded',
  }

  -- Add title if provided
  if opts.title then
    win_opts.title = opts.title
    win_opts.title_pos = 'center'
  end

  -- Open the window
  local winid = vim.api.nvim_open_win(bufnr, true, win_opts)

  -- Set window options
  vim.wo[winid].winblend = 0
  vim.wo[winid].cursorline = true
  -- Make border invisible by matching it to the background
  vim.wo[winid].winhighlight = 'FloatBorder:Normal'

  -- Set up a keymap to close both windows with 'q' or ESC
  local close_keys = { 'q', '<Esc>' }
  for _, key in ipairs(close_keys) do
    vim.api.nvim_buf_set_keymap(bufnr, 'n', key, '', {
      nowait = true,
      noremap = true,
      silent = true,
      callback = function()
        vim.api.nvim_win_close(winid, true)
        vim.api.nvim_win_close(backdrop_winid, true)
      end,
    })
  end

  return bufnr, winid, backdrop_bufnr, backdrop_winid
end

--- Prompt for input using vim.ui.input with optional custom floating window UI
--- Note: This uses Neovim's vim.ui.input which can be overridden by plugins like dressing.nvim
--- @param opts table Configuration for vim.ui.input
---   - prompt: string - the prompt text
---   - default: string - default value
---   - completion: string - completion mode ('file', 'buffer', etc.)
--- @param on_confirm function(input) Callback function that receives the input
function M.input(opts, on_confirm)
  opts = opts or {}
  vim.ui.input({
    prompt = opts.prompt or 'Input: ',
    default = opts.default,
    completion = opts.completion,
  }, function(input)
    if input then
      on_confirm(input)
    end
  end)
end

return M
