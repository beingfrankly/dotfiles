local scopes = require('kickstart.plugins.scopes')

local M = {}

-- Generic function to map keybindings from a table
local function map_keybindings(keymaps, options)
  options = options or {}
  local default_mode = options.mode or 'n'
  local prefix = options.prefix or ''
  local buffer = options.buffer or false

  for _, mapping in ipairs(keymaps) do
    local keys = mapping[1]
    local func = mapping[2]
    local desc = mapping.desc or ''
    local mode = mapping.mode or default_mode
    local opts = mapping.opts or {}

    -- Merge default options with mapping-specific options
    local final_opts = vim.tbl_extend('force', {
      buffer = buffer,
      desc = prefix .. desc,
      silent = true,
      noremap = true,
    }, opts)

    vim.keymap.set(mode, keys, func, final_opts)
  end
end

-- Picker keymaps (p) - All keymaps that are used to pick buffers, git commits, git branches, Scope from scopes plugin, etc
M.picker = {
  -- Snacks picker commands

  { "<leader>pt", function() Snacks.profiler.scratch() end, desc = "Profiler Scratch Bufer" },
  {
    '<leader>ps',
    function()
      Snacks.picker.projects()
    end,
    desc = '[P]ick [S]cope',
  },
  {
    '<leader>pb',
    function()
      Snacks.picker.buffers()
    end,
    desc = '[P]ick [B]uffer',
  },
  {
    '<leader>pr',
    function()
      Snacks.picker.recent()
    end,
    desc = '[P]ick [R]ecent',
  },
  {
    '<leader>ps',
    function()
      scopes.select_projects()
    end,
    desc = '[P]ick [S]cope',
  },
}

-- Search keymaps (s) - All keymaps that are used to search files, recent files, search words, etc
M.search = {
  {
    '<leader>sf',
    function()
      local opts = {
        dirs = scopes.read_projects()
      }
      Snacks.picker.files(opts)
    end,
    desc = '[S]earch [F]iles',
  },
  {
    '<leader>sF',
    function()
      Snacks.picker.files()
    end,
    desc = '[S]earch all [F]iles',
  },
  {
    '<leader>sw',
    function()
      Snacks.picker.grep_word()
    end,
    desc = '[S]earch current [W]ord',
    mode = { 'n', 'x' },
  },
  {
    '<leader>sg',
    function()
      local opts = {
        dirs = scopes.read_projects()
      }
      Snacks.picker.grep(opts)
    end,
    desc = '[S]earch [G]rep in current scope',
  },
  {
    '<leader>sG',
    function()
      Snacks.picker.grep()
    end,
    desc = '[S]earch all [G]rep',
  },
  {
    '<leader>sr',
    function()
      require('kickstart.functions.search-and-replace').open_centered_float({
        rows = 20,
        cols = 80,
        title = ' Search & Replace ',
      })
    end,
    desc = '[S]earch and [R]eplace',
  },
  -- Java runner
  {
    '<leader>pj',
    function()
      require('kickstart.plugins.java-runner').select_and_run()
    end,
    desc = '[P]ick [J]ava App to Run',
  },
}

-- Toggle keymaps (t) - All keymaps that are used to toggle certain states like relative number, zen mode from Snacks, git blame, etc
M.toggle = {
  -- Git toggles
  {
    '<leader>tb',
    function()
      require('gitsigns').toggle_current_line_blame()
    end,
    desc = '[T]oggle git show [b]lame line',
  },
  {
    '<leader>tD',
    function()
      require('gitsigns').toggle_deleted()
    end,
    desc = '[T]oggle git show [D]eleted',
  },
  -- Zellij navigation toggles
  {
    '<leader>zh',
    '<cmd>ZellijNavigateLeftTab<cr>',
    desc = '[T]oggle [Z]ellij left/tab',
    opts = { silent = true },
  },
  {
    '<leader>zj',
    '<cmd>ZellijNavigateDown<cr>',
    desc = '[T]oggle [Z]ellij down',
    opts = { silent = true },
  },
  {
    '<leader>zk',
    '<cmd>ZellijNavigateUp<cr>',
    desc = '[T]oggle [Z]ellij up',
    opts = { silent = true },
  },
  {
    '<leader>zl',
    '<cmd>ZellijNavigateRightTab<cr>',
    desc = '[T]oggle [Z]ellij right/tab',
    opts = { silent = true },
  },
  -- Explorer toggles
  {
    '<leader>e',
    '<cmd>Yazi<cr>',
    desc = '[T]oggle [E]xplorer at current file',
    mode = { 'n', 'v' },
  },
  {
    '<leader>cw',
    '<cmd>Yazi cwd<cr>',
    desc = '[T]oggle [C]urrent [W]orking directory explorer',
  },
  {
    '<c-up>',
    '<cmd>Yazi toggle<cr>',
    desc = '[T]oggle [Y]azi session',
  },
}

-- Git action keymaps (h) - All keymaps related to git operations
M.git = {
  -- Git navigation
  {
    ']c',
    function()
      if vim.wo.diff then
        vim.cmd.normal { ']c', bang = true }
      else
        require('gitsigns').nav_hunk 'next'
      end
    end,
    desc = 'Jump to next git [c]hange',
  },
  {
    '[c',
    function()
      if vim.wo.diff then
        vim.cmd.normal { '[c', bang = true }
      else
        require('gitsigns').nav_hunk 'prev'
      end
    end,
    desc = 'Jump to previous git [c]hange',
  },
  -- Git actions
  {
    '<leader>hs',
    function()
      require('gitsigns').stage_hunk()
    end,
    desc = 'git [s]tage hunk',
  },
  {
    '<leader>hr',
    function()
      require('gitsigns').reset_hunk()
    end,
    desc = 'git [r]eset hunk',
  },
  {
    '<leader>hS',
    function()
      require('gitsigns').stage_buffer()
    end,
    desc = 'git [S]tage buffer',
  },
  {
    '<leader>hu',
    function()
      require('gitsigns').undo_stage_hunk()
    end,
    desc = 'git [u]ndo stage hunk',
  },
  {
    '<leader>hR',
    function()
      require('gitsigns').reset_buffer()
    end,
    desc = 'git [R]eset buffer',
  },
  {
    '<leader>hp',
    function()
      require('gitsigns').preview_hunk()
    end,
    desc = 'git [p]review hunk',
  },
  {
    '<leader>hb',
    function()
      require('gitsigns').blame_line()
    end,
    desc = 'git [b]lame line',
  },
  {
    '<leader>hd',
    function()
      require('gitsigns').diffthis()
    end,
    desc = 'git [d]iff against index',
  },
  {
    '<leader>hD',
    function()
      require('gitsigns').diffthis('@')
    end,
    desc = 'git [D]iff against last commit',
  },
  -- Visual mode git actions
  {
    '<leader>hs',
    function()
      require('gitsigns').stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
    end,
    desc = 'git [s]tage hunk',
    mode = 'v',
  },
  {
    '<leader>hr',
    function()
      require('gitsigns').reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
    end,
    desc = 'git [r]eset hunk',
    mode = 'v',
  },

  -- git
  { "<leader>gb", function() Snacks.picker.git_branches() end, desc = "Git Branches" },
  { "<leader>gl", function() Snacks.picker.git_log() end,      desc = "Git Log" },
  { "<leader>gL", function() Snacks.picker.git_log_line() end, desc = "Git Log Line" },
  { "<leader>gs", function() Snacks.picker.git_status() end,   desc = "Git Status" },
  { "<leader>gS", function() Snacks.picker.git_stash() end,    desc = "Git Stash" },
  { "<leader>gd", function() Snacks.picker.git_diff() end,     desc = "Git Diff (Hunks)" },
  { "<leader>gf", function() Snacks.picker.git_log_file() end, desc = "Git Log File" },
}

-- Debug keymaps (d) - All keymaps used for debugging
M.debug = {
  {
    '<F5>',
    function()
      require('dap').continue()
    end,
    desc = 'Debug: Start/Continue',
  },
  {
    '<F1>',
    function()
      require('dap').step_into()
    end,
    desc = 'Debug: Step Into',
  },
  {
    '<F2>',
    function()
      require('dap').step_over()
    end,
    desc = 'Debug: Step Over',
  },
  {
    '<F3>',
    function()
      require('dap').step_out()
    end,
    desc = 'Debug: Step Out',
  },
  {
    '<leader>b',
    function()
      require('dap').toggle_breakpoint()
    end,
    desc = 'Debug: Toggle Breakpoint',
  },
  {
    '<leader>B',
    function()
      require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end,
    desc = 'Debug: Set Breakpoint',
  },
  {
    '<F7>',
    function()
      require('dapui').toggle()
    end,
    desc = 'Debug: Toggle UI',
  },
}

-- Code actions keymaps (c) - All keymaps used for code actions and formatting
M.code_actions = {
  -- Formatting
  {
    '<leader>f',
    function()
      require('conform').format { async = true, lsp_format = 'fallback' }
    end,
    desc = '[F]ormat buffer',
    mode = '',
  },
  -- LSP code actions
  {
    '<leader>rn',
    function()
      vim.lsp.buf.rename()
    end,
    desc = '[R]e[n]ame',
  },
  {
    '<leader>ca',
    function()
      vim.lsp.buf.code_action()
    end,
    desc = '[C]ode [A]ction',
    mode = { 'n', 'x' },
  },
}

-- Function to setup all keybindings
function M.setup()
  -- Map picker keybindings
  map_keybindings(M.picker, {
    prefix = 'Picker: ',
  })

  -- Map search keybindings
  map_keybindings(M.search, {
    prefix = 'Search: ',
  })

  -- Map toggle keybindings
  map_keybindings(M.toggle, {
    prefix = 'Toggle: ',
  })

  -- Map git keybindings
  map_keybindings(M.git, {
    prefix = 'Git: ',
  })

  -- Map debug keybindings
  map_keybindings(M.debug, {
    prefix = 'Debug: ',
  })

  -- Map code actions keybindings
  map_keybindings(M.code_actions, {
    prefix = 'Code: ',
  })

  -- Setup buffer-specific keymaps for LSP
  setup_buffer_keymaps()
end

-- Setup buffer-specific keymaps for LSP and Git
function setup_buffer_keymaps()
  -- LSP buffer keymaps
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
    callback = function(event)
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      -- Map LSP picker commands
      map('gd', function()
        Snacks.picker.lsp_definitions()
      end, '[G]oto [D]efinition')

      map('gr', function()
        Snacks.picker.lsp_references()
      end, '[G]oto [R]eferences')

      map('gI', function()
        Snacks.picker.lsp_implementations()
      end, '[G]oto [I]mplementation')

      map('<leader>D', function()
        Snacks.picker.lsp_type_definitions()
      end, 'Type [D]efinition')

      map('<leader>ds', function()
        Snacks.picker.lsp_symbols()
      end, '[D]ocument [S]ymbols')

      map('<leader>ws', function()
        Snacks.picker.lsp_workspace_symbols()
      end, '[W]orkspace [S]ymbols')

      map('gD', function()
        Snacks.picker.lsp_declarations()
      end, '[G]oto [D]eclaration')
    end,
  })

  -- Git buffer keymaps are handled by gitsigns on_attach function
end

return M
