require('snacks').setup {
  input = { enabled = true },
  dashboard = {
    enabled = true,
    preset = {
      header = [[
                                   __
      ___     ___    ___   __  __ /\_\    ___ ___
     / _ `\  / __`\ / __`\/\ \/\ \\/\ \  / __` __`\
    /\ \/\ \/\  __//\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \
    \ \_\ \_\ \____\ \____/\ \___/  \ \_\ \_\ \_\ \_\
     \/_/\/_/\/____/\/___/  \/__/    \/_/\/_/\/_/\/_/
]],
      keys = {
        { icon = ' ', key = 'f', desc = 'Find File', action = ":lua Snacks.dashboard.pick('files')" },
        { icon = ' ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
        { icon = ' ', key = 'g', desc = 'Find Text', action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = ' ', key = 'r', desc = 'Recent Files', action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { icon = ' ', key = 'c', desc = 'Config', action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
        { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
      },
    },
    sections = {
      { section = 'header' },
      { section = 'keys', gap = 1, padding = 1 },
      { title = 'Recent Files', section = 'recent_files', limit = 8, cwd = true, indent = 2, padding = 1 },
      function()
        local ok, worktree = pcall(require, 'lib.worktree')
        if ok then
          return worktree.dashboard_section()
        end
        return nil
      end,
    },
  },
  notifier = {
    enabled = true,
    timeout = 3000,
  },
  profiler = { enabled = true },
  picker = {
    enabled = true,
    formatters = {
      file = {
        filename_first = true,
        truncate = 120,
      },
    },
    sources = {
      lsp_definitions = {
        auto_confirm = true,
      },
      tabs = require('lib.tablist').source,
      gh_pr = {
        -- Add a worktrunk-backed checkout: <C-w> creates/switches to a
        -- dedicated worktree for the selected PR via lib.worktree.switch_to_pr.
        -- Built-in actions (<CR> actions menu, <a-b> browse, yank) are kept
        -- because source config deep-merges with the gh_pr defaults.
        actions = {
          gh_pr_worktree = function(picker, item)
            picker:close()
            if not item or not item.number then
              return
            end
            require('lib.worktree').switch_to_pr(item.number)
          end,
        },
        win = {
          input = {
            keys = {
              ['<c-w>'] = { 'gh_pr_worktree', mode = { 'n', 'i' } },
            },
          },
          list = {
            keys = {
              ['<c-w>'] = { 'gh_pr_worktree', mode = { 'n', 'x' } },
            },
          },
        },
      },
    },
  },
  quickfile = { enabled = true },
  statuscolumn = { enabled = true },
  words = { enabled = true },
  dim = { enabled = true },
  scope = { enabled = true },
  terminal = { enabled = true },
  styles = {
    notification = {},
  },
}

-- Profiler toggles
Snacks.toggle.profiler():map('<leader>pp')
Snacks.toggle.profiler_highlights():map('<leader>ph')

-- Debug globals
_G.dd = function(...)
  Snacks.debug.inspect(...)
end
_G.bt = function()
  Snacks.debug.backtrace()
end
vim.print = _G.dd

-- Override vim.ui with Snacks implementations
vim.ui.input = Snacks.input
vim.ui.select = Snacks.picker.select
