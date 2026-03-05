-- Health check for git worktree plugin

local M = {}

function M.check()
  vim.health.start 'Git Worktree Plugin'

  -- Check plenary.nvim
  local has_plenary, plenary = pcall(require, 'plenary')
  if has_plenary then
    vim.health.ok 'plenary.nvim is installed'
  else
    vim.health.error('plenary.nvim is required', {
      'Install with: { "nvim-lua/plenary.nvim" }',
    })
  end

  -- Check git
  if vim.fn.executable 'git' == 1 then
    local version = vim.fn.system 'git --version'
    vim.health.ok('git is installed: ' .. version:gsub('\n', ''))
  else
    vim.health.error 'git is not installed'
  end

  -- Check snacks.nvim
  local has_snacks, snacks = pcall(require, 'snacks')
  if has_snacks then
    vim.health.ok 'snacks.nvim is installed'
    if snacks.picker then
      vim.health.ok 'snacks.picker is available'
    else
      vim.health.warn('snacks.picker is not enabled', {
        'Enable in your config: picker = { enabled = true }',
      })
    end
  else
    vim.health.warn('snacks.nvim is not installed', {
      'Picker functionality requires snacks.nvim',
      'Install with: { "folke/snacks.nvim" }',
    })
  end

  -- Check if in a git repository
  local git_dir = vim.fn.systemlist 'git rev-parse --git-dir 2>/dev/null'[1]
  if vim.v.shell_error == 0 then
    vim.health.ok('Inside a git repository: ' .. git_dir)

    -- Check for worktrees
    local worktrees = vim.fn.systemlist 'git worktree list'
    if vim.v.shell_error == 0 and #worktrees > 0 then
      vim.health.ok(#worktrees .. ' worktree(s) found')
    else
      vim.health.info 'No worktrees found'
    end
  else
    vim.health.info 'Not in a git repository'
  end

  -- Check state file
  local worktree = require 'custom.plugins.worktree'
  local state_dir = vim.fn.fnamemodify(worktree.state_file, ':h')

  if vim.fn.isdirectory(state_dir) == 1 then
    vim.health.ok('State directory exists: ' .. state_dir)

    if vim.fn.filereadable(worktree.state_file) == 1 then
      vim.health.ok('State file exists: ' .. worktree.state_file)

      -- Try to load state
      local ok, state = pcall(worktree.load_state)
      if ok then
        local count = vim.tbl_count(state or {})
        vim.health.ok('State file is valid (' .. count .. ' worktree(s) tracked)')
      else
        vim.health.warn('State file exists but failed to load', {
          'The file may be corrupted',
          'It will be backed up on next save',
        })
      end
    else
      vim.health.info 'State file will be created on first use'
    end
  else
    vim.health.error('State directory does not exist: ' .. state_dir, {
      'This should not happen',
      'Try running: mkdir -p ' .. state_dir,
    })
  end

  -- Check configuration
  vim.health.info 'Configuration:'
  vim.health.info('  save_state: ' .. tostring(worktree.config.save_state))
  vim.health.info('  buffer_close_on_switch: ' .. tostring(worktree.config.buffer_close_on_switch))
  vim.health.info('  confirm_dirty_switch: ' .. tostring(worktree.config.confirm_dirty_switch))
  vim.health.info('  lsp_restart_timeout: ' .. worktree.config.lsp_restart_timeout .. 'ms')
  vim.health.info('  lsp_restart_check_interval: ' .. worktree.config.lsp_restart_check_interval .. 'ms')
  vim.health.info('  file_open_delay: ' .. worktree.config.file_open_delay .. 'ms')

  -- Check LSP
  local clients = vim.lsp.get_clients()
  if #clients > 0 then
    vim.health.ok(#clients .. ' LSP client(s) active')
  else
    vim.health.info 'No LSP clients active'
  end
end

return M
