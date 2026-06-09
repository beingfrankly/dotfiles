-- Tabpages Sidebar (Snacks.picker custom source)
-- Renders one row per tabpage in a left-edge Snacks.picker sidebar.
-- Mirrors the snacks.explorer source pattern (auto_close=false, jump.close=false,
-- layout = { preset = "sidebar", preview = false }).

local M = {}

-- Cached picker instance for toggle/refresh
M._picker = nil

--- Resolve cwd for a tabpage with a graceful fallback for older Neovim.
---@param tabnr integer tab handle returned by nvim_list_tabpages
---@return string cwd absolute path, or "" if unresolvable
local function tab_cwd(tabnr)
  local ok, cwd = pcall(vim.fn.getcwd, -1, tabnr)
  if ok and cwd and cwd ~= '' then return cwd end
  return vim.fn.getcwd()
end

--- Does any buffer in this tabpage have &modified set?
---@param tabnr integer
---@return boolean
local function tab_has_modified(tabnr)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabnr)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].modified then return true end
  end
  return false
end

--- Finder for the picker — returns one item per tabpage in declared order.
---@return snacks.picker.finder.Item[]
local function finder()
  local items = {}
  for idx, tabnr in ipairs(vim.api.nvim_list_tabpages()) do
    local cwd = tab_cwd(tabnr)
    local label = vim.fn.fnamemodify(cwd, ':t')
    if label == '' then label = '[no cwd]' end
    local modified = tab_has_modified(tabnr)
    local current = tabnr == vim.api.nvim_get_current_tabpage()
    local text = string.format('%s%d  %s%s',
      current and '▸ ' or '  ',
      idx,
      label,
      modified and ' ●' or '')
    table.insert(items, {
      idx = idx,
      tabnr = tabnr,
      cwd = cwd,
      modified = modified,
      text = text,
    })
  end
  return items
end

--- Single-line formatter (no preview pane, no icons).
---@param item table
---@return table[] highlight segments
local function format(item)
  local current = item.tabnr == vim.api.nvim_get_current_tabpage()
  return { { item.text, current and 'CursorLine' or 'Normal' } }
end

--- Picker source spec — register via opts.picker.sources.tabs in snacks setup.
M.source = {
  finder = finder,
  format = format,
  sort = { fields = { 'idx' } },
  matcher = { sort_empty = false, fuzzy = false },
  auto_close = false,
  jump = { close = false },
  focus = 'list',
  hidden = { 'input', 'preview' },
  layout = { preset = 'sidebar', preview = false },
  actions = {
    confirm = function(picker, item)
      if not item then return end
      picker:norm(function() end) -- no-op to silence "needs main win" if any
      vim.cmd('tabnext ' .. item.tabnr)
      picker:find({ refresh = true })
    end,
    close_tab = function(picker, item)
      if not item then return end
      -- Guard: refuse to close the last remaining tab.
      if #vim.api.nvim_list_tabpages() <= 1 then
        vim.notify('Cannot close the last tabpage', vim.log.levels.WARN)
        return
      end
      vim.cmd('tabclose ' .. item.tabnr)
      picker:find({ refresh = true })
    end,
    new_tab = function(picker)
      vim.cmd('tabnew')
      picker:find({ refresh = true })
    end,
  },
  win = {
    list = {
      keys = {
        ['d'] = 'close_tab',
        ['a'] = 'new_tab',
        ['r'] = { 'refresh', mode = { 'n' } },
        ['q'] = 'close',
      },
    },
  },
  on_close = function()
    M._picker = nil
  end,
}

--- Open the picker (called by keymap).
---@return snacks.Picker
function M.open()
  if not _G.Snacks or not _G.Snacks.picker then
    vim.notify('Snacks.picker not loaded yet', vim.log.levels.ERROR)
    return
  end
  M._picker = Snacks.picker.tabs()
  return M._picker
end

--- Toggle the picker: close if open, otherwise open.
function M.toggle()
  if M._picker and not M._picker.closed then
    M._picker:close()
    M._picker = nil
  else
    M.open()
  end
end

--- Refresh the picker if currently open. Safe no-op when closed.
function M.refresh()
  if M._picker and not M._picker.closed then
    pcall(function() M._picker:find({ refresh = true }) end)
  end
end

-- Autocmd group: refresh on tab lifecycle and cwd changes.
local group = vim.api.nvim_create_augroup('LibTablistRefresh', { clear = true })
vim.api.nvim_create_autocmd({ 'TabEnter', 'TabClosed', 'TabNew', 'DirChanged' }, {
  group = group,
  callback = function() M.refresh() end,
})

return M
