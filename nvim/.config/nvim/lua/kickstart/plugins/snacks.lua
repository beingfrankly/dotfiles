return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      input = { enabled = true },
      ---@class snacks.dashboard.Config
      dashboard = {
        enabled = true,
        sections = {
          { section = 'header' },
          { section = 'keys',   gap = 1,              padding = 1 },
          { title = 'Projects', section = 'projects', indent = 2, padding = 1 },
          -- Git Worktree section
          function()
            local ok, worktree = pcall(require, 'custom.plugins.worktree')
            if ok then
              return worktree.dashboard_section()
            end
            return nil
          end,
          { section = 'startup' },
        },
      },
      notifier = {
        enabled = true,
        timeout = 3000,
      },
      profiler = { enabled = true },
      ---@class snacks.picker.Config
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
        },
      },

      ---@class snacks.terminal.Config
      quickfile = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      dim = { enabled = true },
      scope = { enabled = true },
      styles = {
        notification = {
          -- wo = { wrap = true } -- Wrap notifications
        },
      },
    },
    keys = require('kickstart.config.keymaps').commands,
    init = function()
      local Snacks = require 'snacks'


      -- Toggle the profiler
      Snacks.toggle.profiler():map("<leader>pp")
      -- Toggle the profiler highlights
      Snacks.toggle.profiler_highlights():map("<leader>ph")

      vim.api.nvim_create_autocmd('User', {
        pattern = 'VeryLazy',
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd -- Override print to use snacks for `:=` command

          -- Override vim.ui with Snacks implementations
          vim.ui.input = Snacks.input
          vim.ui.select = Snacks.picker.select
        end,
      })
    end,
  },
}
