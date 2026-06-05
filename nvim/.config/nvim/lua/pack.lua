-- Plugin management via Neovim 0.12 native vim.pack
-- Replaces lazy.nvim bootstrap + plugin specs.
--
-- Module convention (followed by sidekick / lualine / diffview / atlas):
--   1. Header comment block — purpose, upstream URL, required env vars
--      or external deps, and any cross-module load order notes.
--   2. Guarded require via the kickstart.util helper, e.g.:
--        local m = require('kickstart.util').try_require('m', 'm.nvim')
--        if not m then return end
--   3. m.setup({ ... }) with config inline.
--   4. vim.keymap.set(...) calls grouped by <leader> prefix.
-- The install list below and the configure block further down should
-- agree on section labels (AI / Git tools / Debug / etc.).

-- ══════════════════════════════════════════════════
-- Install all plugins
-- ══════════════════════════════════════════════════

vim.pack.add({
  -- Theme (configured first for colorscheme)
  'https://github.com/serhez/teide.nvim',

  -- Core framework
  'https://github.com/folke/snacks.nvim',
  'https://github.com/folke/which-key.nvim',
  'https://github.com/echasnovski/mini.nvim',
  'https://github.com/nvim-lualine/lualine.nvim',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/williamboman/mason.nvim',
  'https://github.com/stevearc/conform.nvim',
  'https://github.com/nvim-treesitter/nvim-treesitter',
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('^1') },
  'https://github.com/rafamadriz/friendly-snippets',
  'https://github.com/tpope/vim-sleuth',
  'https://github.com/rachartier/tiny-inline-diagnostic.nvim',

  -- Dependencies (needed by feature plugins)
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-tree/nvim-web-devicons',
  'https://github.com/MunifTanjim/nui.nvim',
  'https://github.com/nvim-neotest/nvim-nio',

  -- Feature plugins
  'https://github.com/folke/todo-comments.nvim',
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/rcarriga/nvim-dap-ui',
  'https://github.com/leoluz/nvim-dap-go',
  'https://github.com/nvim-java/nvim-java',
  'https://github.com/JavaHello/spring-boot.nvim',
  'https://github.com/mikavilpas/yazi.nvim',

  -- AI
  'https://github.com/folke/sidekick.nvim',

  -- Git tools
  'https://github.com/sindrets/diffview.nvim',
  'https://github.com/emrearmagan/atlas.nvim',

  -- Filetype-specific
  'https://github.com/folke/lazydev.nvim',
  { src = 'https://gitlab.com/schrieveslaach/sonarlint.nvim', name = 'sonarlint.nvim' },
  'https://github.com/iamcco/markdown-preview.nvim',
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  'https://github.com/dhruvasagar/vim-table-mode',
}, { load = true })

-- ══════════════════════════════════════════════════
-- Configure plugins (order matters)
-- ══════════════════════════════════════════════════

-- 1. Theme (must be first to set colorscheme)
require('kickstart.plugins.theme')

-- 2. Snacks (dashboard, notifier, picker, profiler)
require('kickstart.plugins.snacks')

-- 3. Core plugins
require('kickstart.plugins.diagnostics')
require('kickstart.plugins.which-key')
require('kickstart.plugins.mini')
require('kickstart.plugins.lualine')
require('kickstart.plugins.autopairs')
require('kickstart.plugins.gitsigns')
require('kickstart.plugins.mason')
require('kickstart.plugins.conform')
require('kickstart.plugins.treesitter')
require('kickstart.plugins.blink')
require('kickstart.plugins.todo-comments')

-- 4. AI (Claude Code + Codex via zellij)
require('kickstart.plugins.sidekick')

-- 5. Git tools (diffview loads first; atlas references :DiffviewOpen)
require('kickstart.plugins.diffview')
require('kickstart.plugins.atlas')

-- 6. Debug suite
require('kickstart.plugins.debug')

-- 7. Java
require('kickstart.plugins.jdtls')

-- 8. Explorer
require('kickstart.plugins.explorer')

-- 9. Filetype-specific (deferred via autocmds inside each module)
require('kickstart.plugins.lazydev')
require('kickstart.plugins.sonarlint')
require('kickstart.plugins.markdown')
require('kickstart.plugins.java-extras')

-- 10. Build hooks
require('pack-hooks')
