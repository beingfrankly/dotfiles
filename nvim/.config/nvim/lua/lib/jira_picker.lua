-- lib/jira_picker.lua — Snacks-based Jira issue picker.
-- <CR> switches into the ticket's worktree, or creates one if none exists.
-- <C-o> opens in browser, <C-y> yanks key, <Tab>/<S-Tab> cycles views.
-- Spec reference: docs/jira-picker-spec.md §6.3, §6.4, §6.5, §6.6.

local M = {}

-- ---------------------------------------------------------------------------
-- Config (overridable via M.setup{})
-- ---------------------------------------------------------------------------

-- nf(cp) yields a single UTF-8 character from a codepoint; used so the
-- status_icons table below stays terminal-portable (no invisible glyphs
-- in source). Codepoints follow nerd-fonts v3 (nf-md-* in plane 15).
local function nf(cp) return vim.fn.nr2char(cp) end

M.config = {
  views = {
    {
      name = 'Sprint II',
      jql = 'project = II AND sprint in openSprints() ORDER BY rank ASC',
    },
  },
  max_results = 50,
  branch_prefix = 'feature/',
  confirm_branch_name = true,
  use_icons = true,
  status_icons = {
    { match = 'done',        icon = nf(0xF05E0), hl = 'DiagnosticOk'    }, -- nf-md-check_circle_outline
    { match = 'closed',      icon = nf(0xF0E1E), hl = 'DiagnosticOk'    }, -- nf-md-check_bold
    { match = 'resolved',    icon = nf(0xF012C), hl = 'DiagnosticOk'    }, -- nf-md-check_all
    { match = 'in progress', icon = nf(0xF0954), hl = 'DiagnosticInfo'  }, -- nf-md-progress_clock
    { match = 'in review',   icon = nf(0xF06D0), hl = 'DiagnosticInfo'  }, -- nf-md-eye_outline
    { match = 'blocked',     icon = nf(0xF0156), hl = 'DiagnosticError' }, -- nf-md-cancel
    { match = 'impediment',  icon = nf(0xF05CE), hl = 'DiagnosticError' }, -- nf-md-alert_circle_outline
    { match = 'to do',       icon = nf(0xF0131), hl = 'Comment'         }, -- nf-md-checkbox_blank_circle_outline
    { match = 'open',        icon = nf(0xF0130), hl = 'Comment'         }, -- nf-md-circle_outline
    { match = 'backlog',     icon = nf(0xF0F0D), hl = 'Comment'         }, -- nf-md-tray_full
  },
  status_icon_default = { icon = nf(0xF128), hl = 'Normal' }, -- nf-fa-question
}

function M.setup(opts)
  opts = opts or {}
  -- status_icons: user override REPLACES the default table entirely
  -- (per nvim-taa acceptance) — deep_extend would otherwise merge by
  -- index and leak unspecified default entries through.
  if opts.status_icons ~= nil then
    M.config.status_icons = opts.status_icons
    opts = vim.deepcopy(opts)
    opts.status_icons = nil
  end
  M.config = vim.tbl_deep_extend('force', M.config, opts)
end

-- Module state: 1-based index into M.config.views; set by M.open() and
-- mutated by jira_next_view / jira_prev_view actions.
M._current_view_index = 1

-- Pagination state for the current picker session.
-- Reset on view switch and on M.open(). When loading_more is true, the
-- next finder run requests `page_token = next_token` and APPENDS to items.
-- @type { view_index: integer, items: table[], next_token: string|nil, loading_more: boolean }|nil
M._page_state = nil

-- ---------------------------------------------------------------------------
-- Status lookup (§6.4) — returns { icon, hl } from M.config.status_icons
-- with case-insensitive substring match, falling back to status_icon_default.
-- ---------------------------------------------------------------------------

local function lookup_status(status)
  local lower = string.lower(status or '')
  for _, entry in ipairs(M.config.status_icons or {}) do
    if lower:find(entry.match, 1, true) then
      return entry
    end
  end
  return M.config.status_icon_default
end

-- Match a worktree branch name against a Jira ticket key with an anchored
-- check, so II-12 does not match a worktree branched for II-123.
local function branch_matches_key(branch_name, key)
  if not branch_name or not key then return false end
  local b, k = branch_name:upper(), key:upper()
  local s = b:find(k, 1, true)
  if not s then return false end
  local after = b:sub(s + #k, s + #k)
  return after == '' or not after:match('%d')
end

-- ---------------------------------------------------------------------------
-- Preview pane (synchronous — uses cached _raw)
-- ---------------------------------------------------------------------------

local function make_preview(ctx)
  local item = ctx.item
  if not item then return false end
  local lines = {
    '# ' .. (item.key or '') .. ' — ' .. (item.summary or ''),
    '',
    ('Status:    %s'):format(item.status or ''),
    ('Type:      %s'):format(item.issuetype or ''),
    ('Priority:  %s'):format(item.priority or ''),
    ('Assignee:  %s'):format(item.assignee or '(unassigned)'),
    ('Reporter:  %s'):format(item.reporter or ''),
    ('Labels:    %s'):format(table.concat(item.labels or {}, ', ')),
    ('Updated:   %s'):format(item.updated or ''),
    ('URL:       %s'):format(item.url or ''),
  }
  vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines)
  vim.bo[ctx.buf].filetype = 'markdown'
  return true
end

-- ---------------------------------------------------------------------------
-- Finder — coroutine-bridged async (§6.3)
-- ---------------------------------------------------------------------------

-- Snacks finder protocol: the picker calls `_find(picker.opts, ctx)` and
-- expects the return value to be either a table of items or an async
-- function `(cb) -> nil`. The async function is wrapped in `Async.new(...)`
-- so `Async.running()` inside it returns the task. See
-- `snacks/picker/source/proc.lua:21-26` for the canonical two-layer shape.
local function jira_finder(_opts, _ctx)
  local Async = require('snacks.picker.util.async')

  -- Worktree lookup runs HERE in the outer closure (main thread / event loop
  -- context), NOT inside the inner function(cb). vim.fn.systemlist and
  -- vim.fn.getcwd crash if invoked from the libuv check-timer context that
  -- the inner closure runs under — same hazard as the Phase 2 regression
  -- documented in docs/jira-picker-spec.md §6.3 rev. 4.
  local output = vim.fn.systemlist('git worktree list --porcelain')
  local cwd = vim.fn.getcwd()
  local worktrees = {}
  if vim.v.shell_error == 0 then
    worktrees = require('lib.worktree')._parse_porcelain(output, cwd)
  end

  ---@async
  return function(cb)
    local view = M.config.views[M._current_view_index]
    if not view then
      return
    end
    local jira = require('lib.jira')
    local task = Async.running()
    local result, err, page

    -- Pagination state management: reset on fresh run, consume loading_more flag.
    local state = M._page_state
    local page_token = nil
    if state == nil or state.view_index ~= M._current_view_index then
      state = { view_index = M._current_view_index, items = {}, next_token = nil, loading_more = false }
      M._page_state = state
    elseif state.loading_more then
      page_token = state.next_token
      state.loading_more = false
    end

    local cancel = jira.search(
      view.jql,
      { max_results = M.config.max_results, page_token = page_token },
      function(issues, e, pg)
        result, err, page = issues, e, pg
        if task then
          task:resume()
        end
      end
    )

    -- Abort hook — fires on picker close or view switch. We MUST NOT call
    -- cb() after this; snacks treats post-done callbacks as a bug
    -- ("Finder yielded after done").
    if task then
      task:on('abort', function()
        if cancel then pcall(cancel) end
      end)
      task:suspend()
      if task:aborted() then
        return
      end
    end

    if err then
      vim.schedule(function()
        vim.notify('jira: ' .. err, vim.log.levels.ERROR)
      end)
      return
    end

    for _, item in ipairs(result or {}) do
      for _, wt in ipairs(worktrees) do
        if branch_matches_key(wt.branch_name, item.key) then
          item.worktree_path = wt.path
          break
        end
      end
      -- snacks matcher needs item.text to filter against.
      item.text = (item.key or '') .. ' ' .. (item.summary or '')
      table.insert(state.items, item)
    end

    -- Update pagination cursor.
    state.next_token = page and page.next_page_token or nil

    -- Emit all accumulated items (this run + previous pages).
    for _, item in ipairs(state.items) do
      cb(item)
    end

    -- If more pages are available, emit a synthetic load-more sentinel row.
    if state.next_token then
      cb({
        key = '…',
        summary = string.format('Load more  (loaded %d)', #state.items),
        status = '',
        text = '\0load_more', -- never matches a user query
        _load_more = true,
      })
    end
  end
end

-- ---------------------------------------------------------------------------
-- Format — returns snacks.picker.Highlight[] (§6.3)
-- ---------------------------------------------------------------------------

local function format_row(item, _picker)
  if item._load_more then
    local out = {}
    table.insert(out, { '  ' })                                   -- worktree-indicator gap
    table.insert(out, { ('%-10s'):format('…'), 'Comment' })
    table.insert(out, { '  ' })
    table.insert(out, { item.summary or '', 'Special' })
    return out
  end
  local out = {}
  if item.worktree_path then
    table.insert(out, { ' ', 'DiagnosticHint' })
  else
    table.insert(out, { '  ' })
  end
  table.insert(out, { ('%-10s'):format(item.key or ''), 'Identifier' })
  table.insert(out, { '  ' })
  local s = lookup_status(item.status)
  if M.config.use_icons then
    table.insert(out, { s.icon .. ' ', s.hl })
  else
    table.insert(out, { ('%-14s'):format(item.status or ''), s.hl })
  end
  table.insert(out, { '  ' })
  table.insert(out, { item.summary or '', 'Normal' })
  return out
end

-- ---------------------------------------------------------------------------
-- Actions
-- ---------------------------------------------------------------------------

local function action_open_browser(_picker, item)
  if not item or not item.url then return end
  vim.ui.open(item.url)
end

local function action_yank_key(_picker, item)
  if not item or not item.key then return end
  vim.fn.setreg('+', item.key)
  vim.notify('Yanked ' .. item.key)
end

-- Cycle to the next/previous view in M.config.views. Wraps around at the
-- boundaries. Mutates module state, updates picker title, and triggers a
-- finder refresh.
--
-- Mutating `picker.title` directly is correct: Snacks' update_titles()
-- (snacks/picker/core/picker.lua:384-387) reads `self.title` as the title
-- template source, and `picker:find({refresh = true})` calls update_titles
-- internally (picker.lua:835) — so the new title is rendered on the next
-- finder run without any documented setter.
local function action_next_view(picker, _item)
  local n = #M.config.views
  if n <= 1 then return end
  M._current_view_index = (M._current_view_index % n) + 1
  local view = M.config.views[M._current_view_index]
  picker.title = string.format('Jira — %s', view.name)
  picker:find({ refresh = true })
end

local function action_prev_view(picker, _item)
  local n = #M.config.views
  if n <= 1 then return end
  M._current_view_index = ((M._current_view_index - 2) % n) + 1
  local view = M.config.views[M._current_view_index]
  picker.title = string.format('Jira — %s', view.name)
  picker:find({ refresh = true })
end

-- ---------------------------------------------------------------------------
-- Open
-- ---------------------------------------------------------------------------

--- Open the Jira picker.
--- @param opts table?  { views = view[]?, start_view = number? }
function M.open(opts)
  opts = opts or {}
  local views = opts.views or M.config.views
  if not views or #views == 0 then
    vim.notify('jira picker: no views configured', vim.log.levels.ERROR)
    return
  end

  local idx = math.max(1, math.min(opts.start_view or 1, #views))
  M._current_view_index = idx
  M._page_state = nil
  local view = views[idx]

  -- Fail fast if credentials are missing — better than empty picker.
  local jira = require('lib.jira')
  local _, cfg_err = jira.config()
  if cfg_err then
    vim.notify(cfg_err, vim.log.levels.ERROR)
    return
  end

  return require('snacks').picker.pick({
    source = 'jira',
    title = string.format('Jira — %s', view.name),
    finder = jira_finder,
    format = format_row,
    preview = make_preview,
    confirm = function(picker, item)
      if item and item._load_more then
        if M._page_state then
          M._page_state.loading_more = true
        end
        picker:find({ refresh = true })
        return
      end
      if not item or not item.key then return end
      picker:close()
      vim.schedule(function()
        local wt = require('lib.worktree')
        if item.worktree_path then
          wt.switch_to_worktree(item.worktree_path)
        else
          wt.create_for_ticket(item.key, item.summary, {
            branch_prefix = M.config.branch_prefix,
            confirm = M.config.confirm_branch_name ~= false,
          })
        end
      end)
    end,
    actions = {
      jira_open_browser = action_open_browser,
      jira_yank_key = action_yank_key,
      jira_next_view = action_next_view,
      jira_prev_view = action_prev_view,
    },
    win = {
      input = {
        keys = {
          ['<C-o>'] = { 'jira_open_browser', mode = { 'i', 'n' } },
          ['<C-y>'] = { 'jira_yank_key', mode = { 'i', 'n' } },
          ['<Tab>'] = { 'jira_next_view', mode = { 'i', 'n' } },
          ['<S-Tab>'] = { 'jira_prev_view', mode = { 'i', 'n' } },
        },
      },
      -- Override snacks' default multi-select on <Tab>/<S-Tab> in the list
      -- window. The list window has no insert mode, so the mode set is
      -- { 'n', 'x' } (normal + visual), matching snacks' defaults.
      list = {
        keys = {
          ['<Tab>'] = { 'jira_next_view', mode = { 'n', 'x' } },
          ['<S-Tab>'] = { 'jira_prev_view', mode = { 'n', 'x' } },
        },
      },
    },
  })
end

return M
