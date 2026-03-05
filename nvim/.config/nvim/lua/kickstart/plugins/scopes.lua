---@diagnostic disable: undefined-global
local M = {}
local uv = vim.uv

-- ==== Config ====
local options = {
  indicators = {
    'package.json',
    'pom.xml',
    'pyproject.toml',
    'go.mod',
    'Cargo.toml',
  },
  ignore_dirs = {
    'node_modules',
    '.git',
    'dist',
    'build',
    'target',
    '.next',
    '.vscode',
    '.idea',
  },
}

M.path = {}
M.path.sep = (function()
  if jit then
    local os = string.lower(jit.os)
    if os == 'linux' or os == 'osx' or os == 'bsd' then
      return '/'
    else
      return '\\'
    end
  else
    return package.config:sub(1, 1)
  end
end)()

-- ==== Utils ====
local function get_scopes_dir()
  return vim.fn.expand('$HOME/.local/share/nvim/scopes')
end

local function ensure_dir_exists(path)
  if not uv.fs_stat(path) then
    uv.fs_mkdir(path, 493) -- 493 = 0755 in decimal
  end
end

local function find_git_root(start_path)
  local path = start_path or vim.fn.getcwd()
  while path ~= '/' do
    if vim.fn.isdirectory(path .. '/.git') == 1 then
      return path
    end
    path = vim.fn.fnamemodify(path, ':h')
  end
  return nil
end

local function get_monorepo_name(root)
  return vim.fn.fnamemodify(root, ':t')
end

local function has_indicator(dir)
  for _, indicator in ipairs(options.indicators) do
    if vim.fn.filereadable(dir .. '/' .. indicator) == 1 then
      return true
    end
  end
  return false
end

local function should_ignore(dir_name)
  return vim.tbl_contains(options.ignore_dirs, dir_name) or dir_name:match '^%.'
end

local function find_directories(root)
  local dirs = {}
  local entries = vim.fn.readdir(root)

  for _, entry in ipairs(entries) do
    if not should_ignore(entry) then
      local full_path = root .. '/' .. entry
      if vim.fn.isdirectory(full_path) == 1 and has_indicator(full_path) then
        table.insert(dirs, {
          name = entry,
          path = full_path,
        })
      end
    end
  end

  return dirs
end


-- ==== Main Functions ====
function M.setup(opts)
  -- Merge options
  options = vim.tbl_deep_extend('force', options, opts or {})
  
  -- Ensure scopes directory exists
  local scopes_dir = get_scopes_dir()
  ensure_dir_exists(scopes_dir)
  
  if not scopes_dir then
    Snacks.notify.error('Scopes directory not initialized')
  end
end

function M.write_projects(selected)
  local root = find_git_root()
  if not root then
    Snacks.notify.error('Not in a git repository')
    return
  end

  local repo_name = get_monorepo_name(root)
  local path = vim.fn.expand('$HOME/.local/share/nvim/scopes/' .. repo_name .. '.txt')
  local dir = vim.fn.fnamemodify(path, ':h')

  -- Ensure directory exists
  ensure_dir_exists(dir)

  if #selected == 0 then
    Snacks.notify.warn('No projects selected')
    return
  end

  -- Write to file
  local fd = uv.fs_open(path, 'w', 438) -- 438 = 0666 in decimal (rw-rw-rw-)
  if fd then
    local content = table.concat(selected, '\n')
    uv.fs_write(fd, content)
    uv.fs_close(fd)
    Snacks.notify.info('Selected ' .. #selected .. ' project(s) written to scopes file')
  else
    Snacks.notify.error('Failed to open file: ' .. path)
  end
end

function M.read_projects()
  local root = find_git_root()
  if not root then
    Snacks.notify.error('Not in a git repository')
    return {}
  end

  local repo_name = get_monorepo_name(root)
  local path = vim.fn.expand('$HOME/.local/share/nvim/scopes/' .. repo_name .. '.txt')
  
  if not uv.fs_stat(path) then
    return {}
  end

  local fd = uv.fs_open(path, 'r', 438)
  if not fd then
    return {}
  end

  local stat = uv.fs_fstat(fd)
  local content = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)

  if not content then
    return {}
  end

  -- Split content into lines and filter out empty lines
  local paths = {}
  for line in content:gmatch("[^\r\n]+") do
    if line ~= "" then
      table.insert(paths, line)
    end
  end

  return paths
end

function M.select_projects(start_idx)
  local root = find_git_root()
  if not root then
    Snacks.notify.error('Not in a git repository')
    return
  end

  local dirs = find_directories(root)
  if #dirs == 0 then
    Snacks.notify.warn('No project directories found in ' .. root)
    return
  end

  -- Read currently selected projects to pre-fill selection
  local current_selections = M.read_projects()
  local selection_map = {}
  for _, path in ipairs(current_selections) do
    selection_map[path] = true
  end

  -- Create items for the picker
  local items = {}
  local longest_name = 0
  for i, dir in ipairs(dirs) do
    table.insert(items, {
      idx = i,
      score = i,
      text = dir.path,
      name = dir.name,
    })
    longest_name = math.max(longest_name, #dir.name)
  end
  longest_name = longest_name + 2

  local repo_name = get_monorepo_name(root)

  -- Use Snacks picker with custom format
  local picker_opts = {
    items = items,
    title = 'Pick Scope: ' .. repo_name,
    focus = "list",  -- Focus list instead of input (no search needed)
    format = function(item)
      -- Just show the project name (no full path)
      return { { item.name, 'SnacksPickerLabel' } }
    end,
    layout = {
      preset = "vscode",
      preview = false,
    },
    icons = {
      ui = {
        selected = "✓ ",      -- Checkmark for selected items
        unselected = "  ",    -- Empty space for unselected items
      },
    },
    formatters = {
      selected = {
        show_always = true,   -- Always show selection indicator
        unselected = true,    -- Show unselected icon for unselected items
      },
    },
    -- Pre-select currently configured projects
    on_show = function(picker)
      -- Mark items as selected if they're in the current selection
      for _, item in ipairs(picker.list.items) do
        if selection_map[item.text] then
          picker.list.selected_map[item.text] = item
        end
      end
      -- Refresh the display to show selections
      picker.list:update()
    end,
    confirm = function(picker, item)
      -- Collect all selected items (supports multi-select with 'v' key)
      local paths = {}
      for path, _ in pairs(picker.list.selected_map) do
        table.insert(paths, path)
      end

      -- If nothing explicitly selected, use current item
      if #paths == 0 and item then
        table.insert(paths, item.text)
      end

      M.write_projects(paths)
      picker:close()
    end,
  }

  -- Store for resume capability
  M._last_picker_opts = picker_opts
  Snacks.picker(picker_opts)
end

-- Resume last picker
function M.resume_project_picker()
  if M._last_picker_opts then
    Snacks.picker(M._last_picker_opts)
  else
    M.select_projects()
  end
end

return M
  