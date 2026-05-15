-- Git Worktree Integration
-- Provides worktree switching with full Neovim state management

-- Check for required dependencies
local has_plenary, Job = pcall(require, 'plenary.job')
if not has_plenary then
  vim.notify('worktree.lua requires nvim-lua/plenary.nvim', vim.log.levels.ERROR)
  return {}
end

local M = {}

-- Module-local guard so worktrunk JSON-decode warnings do not spam
local _worktrunk_warn_shown = false

--- Run `git-wt <args> --format=json` and decode the JSON output.
---@param args string[] arguments AFTER `git-wt`; the helper appends `--format=json`
---@return table|nil decoded JSON, or nil on missing CLI / shell error / decode failure
---@return string|nil err_kind nil on success; 'missing' | 'shell_error' | 'decode' on failure
---@return string|nil err_text raw output for shell_error/decode so the caller can surface it
function M._worktrunk_json(args)
  if vim.fn.executable('git-wt') ~= 1 then
    return nil, 'missing', nil
  end
  local cmd = vim.list_extend({ 'git-wt' }, args)
  table.insert(cmd, '--format=json')
  local output = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return nil, 'shell_error', table.concat(output, '\n')
  end
  local raw = table.concat(output, '\n')
  local ok, decoded = pcall(vim.json.decode, raw)
  if not ok or type(decoded) ~= 'table' then
    if not _worktrunk_warn_shown then
      _worktrunk_warn_shown = true
      vim.notify(
        'worktree.lua: failed to decode git-wt JSON output; falling back to git --porcelain',
        vim.log.levels.WARN
      )
    end
    return nil, 'decode', raw
  end
  return decoded, nil, nil
end

-- Configuration
M.config = {
  save_state = true,
  lsp_restart_timeout = 5000,
  lsp_restart_check_interval = 100,
  buffer_close_on_switch = true,
  confirm_dirty_switch = true,
  file_open_delay = 100, -- Delay after LSP restart before opening file
}

-- State file for tracking last file per worktree
M.state_file = vim.fn.stdpath 'state' .. '/worktree_state.json'

---Setup configuration
---@param opts table|nil Configuration options
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

---Parse git worktree list output
---Prefers worktrunk (git-wt) JSON when available; falls back to git --porcelain.
---@return table|nil List of worktrees with path, branch, sha, is_current, branch_name,
---                  and (when from worktrunk) ahead, behind, clean, ci_status
function M.list_worktrees()
  local cwd = vim.fn.getcwd()

  -- Check if we're in a git repo
  local git_dir = vim.fn.systemlist('git rev-parse --git-dir 2>/dev/null')[1]
  if vim.v.shell_error ~= 0 then
    return nil
  end

  -- ── worktrunk fast-path ───────────────────────────────────────────────────
  local decoded = M._worktrunk_json({ 'list' })
  if decoded then
    local worktrees = {}
    for _, entry in ipairs(decoded) do
      -- Skip bare/orphan main entries (entries with no real working tree)
      if not (entry.is_main and vim.fn.isdirectory(entry.path) ~= 1) then
        local wt = {
          path = entry.path,
          branch = 'refs/heads/' .. (entry.branch or ''),
          branch_name = entry.branch or 'detached',
          sha = entry.commit and entry.commit.sha or nil,
          is_current = entry.is_current == true,
          -- worktrunk-enriched fields
          ahead = (entry.main and entry.main.ahead) or 0,
          behind = (entry.main and entry.main.behind) or 0,
          clean = (entry.working_tree ~= nil)
            and (entry.working_tree.staged == 0
              and entry.working_tree.modified == 0
              and entry.working_tree.untracked == 0)
            or false,
          ci_status = entry.ci and entry.ci.status or nil,
        }
        table.insert(worktrees, wt)
      end
    end
    return worktrees
  end
  -- fall through to git --porcelain path

  -- ── git-porcelain fallback ────────────────────────────────────────────────
  local output = vim.fn.systemlist 'git worktree list --porcelain'
  if vim.v.shell_error ~= 0 then
    return nil
  end

  local worktrees = {}
  local current = {}

  for _, line in ipairs(output) do
    if line:match '^worktree ' then
      if current.path then
        table.insert(worktrees, current)
      end
      current = { path = line:match '^worktree (.+)' }
    elseif line:match '^HEAD ' then
      current.sha = line:match '^HEAD (%w+)'
    elseif line:match '^branch ' then
      current.branch = line:match '^branch (.+)'
    elseif line:match '^bare' then
      current.bare = true
    end
  end

  -- Add last worktree
  if current.path then
    table.insert(worktrees, current)
  end

  -- Filter out bare repo entry
  worktrees = vim.tbl_filter(function(wt)
    return not wt.bare
  end, worktrees)

  -- Add derived fields
  for _, wt in ipairs(worktrees) do
    wt.is_current = wt.path == cwd
    wt.branch_name = wt.branch and wt.branch:match '([^/]+)$' or 'detached'
  end

  return worktrees
end

---Get git status for a worktree asynchronously
---@param path string Worktree path
---@param callback function Callback function(status)
function M.get_worktree_status_async(path, callback)
  local status = { clean = false, ahead = 0, behind = 0 }

  -- Check if working tree is clean
  Job
    :new({
      command = 'git',
      args = { '-C', path, 'status', '--porcelain' },
      on_exit = vim.schedule_wrap(function(j, exit_code)
        if exit_code == 0 then
          local result = j:result()
          status.clean = #result == 0 or (result[1] == nil)
        end

        -- Check ahead/behind
        Job
          :new({
            command = 'git',
            args = { '-C', path, 'rev-list', '--left-right', '--count', 'HEAD...@{upstream}' },
            on_exit = vim.schedule_wrap(function(j2, exit_code2)
              if exit_code2 == 0 and j2:result()[1] then
                local ahead, behind = j2:result()[1]:match '(%d+)%s+(%d+)'
                status.ahead = tonumber(ahead) or 0
                status.behind = tonumber(behind) or 0
              end
              callback(status)
            end),
          })
          :start()
      end),
    })
    :start()
end

---Get git status for a worktree synchronously (for current worktree only)
---@param path string Worktree path
---@return table Status with clean, ahead, behind flags
function M.get_worktree_status(path)
  local cwd = vim.fn.getcwd()
  vim.fn.chdir(path)

  local status = { clean = false, ahead = 0, behind = 0 }

  -- Check if working tree is clean
  local diff_output = vim.fn.system 'git status --porcelain'
  status.clean = diff_output == ''

  -- Check ahead/behind
  local tracking = vim.fn.systemlist 'git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null'[1]
  if tracking then
    local ahead, behind = tracking:match '(%d+)%s+(%d+)'
    status.ahead = tonumber(ahead) or 0
    status.behind = tonumber(behind) or 0
  end

  vim.fn.chdir(cwd)
  return status
end

---Load state from file
---@return table State map of worktree_path -> last_file
function M.load_state()
  local file = io.open(M.state_file, 'r')
  if not file then
    return {}
  end

  local content = file:read '*all'
  file:close()

  if content == '' then
    return {}
  end

  local ok, state = pcall(vim.json.decode, content)
  if not ok then
    vim.notify('Failed to load worktree state: ' .. tostring(state), vim.log.levels.WARN)
    -- Backup corrupted file
    local backup = M.state_file .. '.backup'
    vim.fn.rename(M.state_file, backup)
    vim.notify('Corrupted state file backed up to: ' .. backup, vim.log.levels.INFO)
    return {}
  end
  return state or {}
end

---Save state to file
---@param state table State map of worktree_path -> last_file
function M.save_state(state)
  local file = io.open(M.state_file, 'w')
  if not file then
    vim.notify('Failed to save worktree state', vim.log.levels.ERROR)
    return
  end

  local ok, encoded = pcall(vim.json.encode, state)
  if not ok then
    vim.notify('Failed to encode worktree state: ' .. tostring(encoded), vim.log.levels.ERROR)
    file:close()
    return
  end

  file:write(encoded)
  file:close()
end

---Close all buffers from current worktree
---@param current_path string Current worktree path
function M.close_worktree_buffers(current_path)
  local buffers = vim.api.nvim_list_bufs()
  local current_buf = vim.api.nvim_get_current_buf()

  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)

      -- Check if buffer belongs to current worktree
      if buf_name ~= '' and buf_name:match('^' .. vim.pesc(current_path)) then
        -- Skip if this is the current buffer (will be handled by cd + edit)
        if buf ~= current_buf then
          -- Skip special buffers (terminal, scratch, etc.)
          local buftype = vim.bo[buf].buftype
          if buftype == '' or buftype == 'acwrite' then
            -- Save if modified (use modern API)
            if vim.bo[buf].modified then
              local ok = pcall(vim.api.nvim_buf_call, buf, function()
                vim.cmd 'write'
              end)
              if not ok then
                vim.notify('Failed to save buffer: ' .. buf_name, vim.log.levels.WARN)
              end
            end

            -- Delete buffer
            pcall(vim.api.nvim_buf_delete, buf, { force = false })
          end
        end
      end
    end
  end
end

---Restart all LSP clients with proper wait logic
---@param callback function|nil Callback to run after LSP restart
function M.restart_lsp(callback)
  local clients = vim.lsp.get_clients()

  if #clients == 0 then
    if callback then
      callback()
    end
    return
  end

  vim.notify('Restarting ' .. #clients .. ' LSP servers...', vim.log.levels.INFO)

  -- Stop all clients
  for _, client in ipairs(clients) do
    vim.lsp.stop_client(client.id)
  end

  -- Wait for all clients to actually stop
  local max_wait = M.config.lsp_restart_timeout
  local check_interval = M.config.lsp_restart_check_interval
  local elapsed = 0

  vim.defer_fn(function()
    local check_stopped
    check_stopped = function()
      if vim.tbl_isempty(vim.lsp.get_clients()) then
        -- All clients stopped, trigger restart
        vim.cmd 'edit'
        if callback then
          -- Give LSP a moment to attach
          vim.defer_fn(callback, M.config.file_open_delay)
        end
        return
      end

      elapsed = elapsed + check_interval
      if elapsed >= max_wait then
        vim.notify('LSP restart timeout - forcing', vim.log.levels.WARN)
        vim.cmd 'edit'
        if callback then
          vim.defer_fn(callback, M.config.file_open_delay)
        end
        return
      end

      vim.defer_fn(check_stopped, check_interval)
    end
    check_stopped()
  end, check_interval)
end

---Reset all plugin state for clean switch
function M.reset_plugin_state()
  -- Close floating windows
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= '' then
      vim.api.nvim_win_close(win, true)
    end
  end

  -- Clear quickfix and location lists
  vim.fn.setqflist {}
  vim.fn.setloclist(0, {})

  -- Refresh git signs if available
  local ok, gitsigns = pcall(require, 'gitsigns')
  if ok then
    gitsigns.refresh()
  end
end

---Switch to a different worktree
---@param target_path string Path to target worktree
---@param opts table|nil Options: { save_state = true, force = false }
function M.switch_to_worktree(target_path, opts)
  opts = vim.tbl_extend('force', {
    save_state = M.config.save_state,
    force = false,
  }, opts or {})

  local current_path = vim.fn.getcwd()

  -- Check if already in target worktree
  if current_path == target_path then
    vim.notify('Already in worktree: ' .. target_path, vim.log.levels.INFO)
    return
  end

  -- Verify target path exists
  if vim.fn.isdirectory(target_path) ~= 1 then
    vim.notify('Worktree not found: ' .. target_path, vim.log.levels.ERROR)
    return
  end

  -- Check if current worktree is dirty
  if M.config.confirm_dirty_switch and not opts.force then
    local current_status = M.get_worktree_status(current_path)
    if not current_status.clean then
      local confirm = vim.fn.confirm('Current worktree has uncommitted changes. Continue?', '&Yes\n&No', 2)
      if confirm ~= 1 then
        return
      end
    end
  end

  -- Save current file to state
  if opts.save_state then
    local current_file = vim.api.nvim_buf_get_name(0)
    if current_file ~= '' then
      local state = M.load_state()
      state[current_path] = current_file
      M.save_state(state)
    end
  end

  -- Change directory first
  vim.cmd('cd ' .. vim.fn.fnameescape(target_path))

  -- Reset plugin state (close floating windows, clear quickfix)
  M.reset_plugin_state()

  -- Restart LSP with callback to open file and cleanup
  M.restart_lsp(function()
    -- Close old worktree buffers AFTER switching
    if M.config.buffer_close_on_switch then
      vim.schedule(function()
        M.close_worktree_buffers(current_path)
      end)
    end

    -- Load last file or show dashboard
    local state = M.load_state()
    local last_file = state[target_path]

    if last_file and vim.fn.filereadable(last_file) == 1 then
      vim.cmd('edit ' .. vim.fn.fnameescape(last_file))
      vim.notify('Switched to worktree: ' .. target_path, vim.log.levels.INFO)
    else
      -- Show dashboard if available
      local ok, snacks = pcall(require, 'snacks')
      if ok and snacks.dashboard then
        snacks.dashboard.open()
      end
      vim.notify('Switched to worktree: ' .. target_path, vim.log.levels.INFO)
    end
  end)
end

---Format worktree for picker display
---@param wt table Worktree data
---@param status table Status data
---@return table Picker item
function M.format_worktree_item(wt, status)
  local icon = wt.is_current and '●' or ' '
  local branch = wt.branch_name or 'detached'

  -- Status badges
  local badges = {}
  if status.clean then
    table.insert(badges, '[✓ clean]')
  else
    table.insert(badges, '[⚠ dirty]')
  end

  if status.ahead > 0 then
    table.insert(badges, '[↑' .. status.ahead .. ']')
  end

  if status.behind > 0 then
    table.insert(badges, '[↓' .. status.behind .. ']')
  end

  local status_str = table.concat(badges, ' ')

  return {
    text = string.format('%s %-40s %s', icon, branch, status_str),
    path = wt.path,
    branch = branch,
  }
end

---Generate preview content for worktree
---@param item table Picker item
---@return string[] Preview lines
function M.preview_worktree(item)
  local cwd = vim.fn.getcwd()
  vim.fn.chdir(item.path)

  local lines = {}

  -- Header
  table.insert(lines, 'Worktree: ' .. item.branch)
  table.insert(lines, 'Path: ' .. item.path)
  table.insert(lines, '')
  table.insert(lines, 'Recent Commits:')
  table.insert(lines, string.rep('─', 50))

  -- Last 5 commits
  local commits = vim.fn.systemlist 'git log --oneline --max-count=5'
  for _, commit in ipairs(commits) do
    table.insert(lines, commit)
  end

  vim.fn.chdir(cwd)
  return lines
end

---Open worktree picker
function M.pick_worktree()
  local worktrees = M.list_worktrees()

  if not worktrees or #worktrees == 0 then
    vim.notify('No worktrees found', vim.log.levels.WARN)
    return
  end

  -- Check if Snacks is available
  local ok, snacks = pcall(require, 'snacks')
  if not ok then
    vim.notify('Snacks.nvim not available', vim.log.levels.ERROR)
    return
  end

  -- Get status for each worktree asynchronously
  local items = {}
  local pending = #worktrees
  local picker_opened = false

  for _, wt in ipairs(worktrees) do
    -- Use synchronous status for current worktree (fast)
    if wt.is_current then
      local status = M.get_worktree_status(wt.path)
      local item = M.format_worktree_item(wt, status)
      table.insert(items, item)
      pending = pending - 1

      if pending == 0 and not picker_opened then
        picker_opened = true
        M.open_picker(snacks, items)
      end
    else
      -- Use async status for other worktrees (non-blocking)
      M.get_worktree_status_async(wt.path, function(status)
        local item = M.format_worktree_item(wt, status)
        table.insert(items, item)
        pending = pending - 1

        if pending == 0 and not picker_opened then
          picker_opened = true
          M.open_picker(snacks, items)
        end
      end)
    end
  end
end

---Open the Snacks picker with worktree items
---@param snacks table Snacks module
---@param items table List of worktree items
function M.open_picker(snacks, items)
  snacks.picker {
    items = items,
    title = ' Git Worktrees [<C-d> delete]',
    prompt = 'Select worktree...',
    format = function(item)
      -- Return a table of highlight segments
      return { { item.text, 'Normal' } }
    end,
    preview = function(item, ctx)
      return {
        text = M.preview_worktree(item),
      }
    end,
    confirm = function(picker, item)
      M.switch_to_worktree(item.path)
    end,
    on_key = {
      ['<C-d>'] = function(ctx)
        local item = ctx.item
        M.delete_worktree(item.path)
        -- Refresh picker
        ctx.refresh()
      end,
    },
  }
end

---Fetch remote branches asynchronously
---@param callback function Called with branch list
function M.fetch_remote_branches(callback)
  -- First fetch from all remotes
  Job
    :new({
      command = 'git',
      args = { 'fetch', '--all' },
      on_exit = vim.schedule_wrap(function(j, exit_code)
        if exit_code ~= 0 then
          vim.notify('Failed to fetch remote branches', vim.log.levels.ERROR)
          callback({})
          return
        end

        -- Then get the list of remote branches
        Job
          :new({
            command = 'git',
            args = { 'branch', '-r', '--sort=-committerdate' },
            on_exit = vim.schedule_wrap(function(j2, exit_code2)
              if exit_code2 ~= 0 then
                vim.notify('Failed to list remote branches', vim.log.levels.ERROR)
                callback({})
                return
              end

              local branches = j2:result()
              local items = {}

              for _, branch in ipairs(branches) do
                -- Skip HEAD pointer and empty lines
                if not branch:match('HEAD') and branch ~= '' then
                  local clean_branch = vim.trim(branch)
                  local remote, name = clean_branch:match('([^/]+)/(.*)')

                  if remote and name then
                    table.insert(items, {
                      text = name,
                      remote = remote,
                      full_name = clean_branch,
                    })
                  end
                end
              end

              callback(items)
            end),
          })
          :start()
      end),
    })
    :start()
end

---Create new worktree from remote branch
---@param branch_name string Branch name (without remote prefix)
---@param remote string Remote name (e.g., 'origin')
function M.create_worktree_from_remote(branch_name, remote)
  -- Get git directory to find bare repo root
  Job
    :new({
      command = 'git',
      args = { 'rev-parse', '--git-dir' },
      on_exit = vim.schedule_wrap(function(j, exit_code)
        if exit_code ~= 0 then
          vim.notify('Not in a git repository', vim.log.levels.ERROR)
          return
        end

        local git_dir = j:result()[1]
        if not git_dir then
          vim.notify('Failed to find git directory', vim.log.levels.ERROR)
          return
        end

        -- Navigate to bare repo root (parent of .git directory)
        local bare_root = vim.fn.fnamemodify(git_dir, ':h')
        local full_remote = remote .. '/' .. branch_name
        local worktree_path = bare_root .. '/' .. branch_name

        -- Check if worktree already exists
        if vim.fn.isdirectory(worktree_path) == 1 then
          vim.notify('Worktree already exists: ' .. branch_name, vim.log.levels.WARN)
          M.switch_to_worktree(worktree_path)
          return
        end

        vim.notify('Creating worktree: ' .. branch_name, vim.log.levels.INFO)

        -- Create worktree
        Job
          :new({
            command = 'git',
            args = { '-C', bare_root, 'worktree', 'add', branch_name, full_remote },
            on_exit = vim.schedule_wrap(function(j_create, create_exit_code)
              if create_exit_code ~= 0 then
                local error_msg = table.concat(j_create:stderr_result(), '\n')
                vim.notify('Failed to create worktree:\n' .. error_msg, vim.log.levels.ERROR)
                return
              end

              vim.notify('Installing dependencies...', vim.log.levels.INFO)

              -- Check if pnpm is available and a package.json exists
              local has_package_json = vim.fn.filereadable(worktree_path .. '/package.json') == 1

              if has_package_json then
                -- Install dependencies with pnpm
                Job
                  :new({
                    command = 'pnpm',
                    args = { 'install' },
                    cwd = worktree_path,
                    on_exit = vim.schedule_wrap(function(j_install, install_exit_code)
                      if install_exit_code == 0 then
                        vim.notify('Worktree ready: ' .. branch_name, vim.log.levels.INFO)
                        M.switch_to_worktree(worktree_path)
                      else
                        local error_msg = table.concat(j_install:stderr_result(), '\n')
                        vim.notify('Failed to install dependencies:\n' .. error_msg, vim.log.levels.ERROR)
                        -- Still switch to worktree even if pnpm fails
                        M.switch_to_worktree(worktree_path)
                      end
                    end),
                  })
                  :start()
              else
                -- No package.json, just switch to the worktree
                vim.notify('Worktree ready: ' .. branch_name, vim.log.levels.INFO)
                M.switch_to_worktree(worktree_path)
              end
            end),
          })
          :start()
      end),
    })
    :start()
end

---Open remote branch picker
function M.pick_remote_branch()
  vim.notify('Fetching remote branches...', vim.log.levels.INFO)

  M.fetch_remote_branches(function(branches)
    if #branches == 0 then
      vim.notify('No remote branches found', vim.log.levels.WARN)
      return
    end

    local ok, snacks = pcall(require, 'snacks')
    if not ok then
      vim.notify('Snacks.nvim not available', vim.log.levels.ERROR)
      return
    end

    snacks.picker {
      items = branches,
      title = ' Remote Branches',
      prompt = 'Create worktree from branch...',
      format = function(item)
        return { { item.text .. '  (' .. item.remote .. ')', 'Normal' } }
      end,
      confirm = function(picker, item)
        M.create_worktree_from_remote(item.text, item.remote)
      end,
    }
  end)
end

---Delete a worktree with safety checks
---@param worktree_path string Path to worktree to delete
function M.delete_worktree(worktree_path)
  local current_path = vim.fn.getcwd()

  -- Prevent deleting current worktree
  if worktree_path == current_path then
    vim.notify('Cannot delete current worktree. Switch first.', vim.log.levels.ERROR)
    return
  end

  -- Check if worktree is dirty
  local cwd = vim.fn.getcwd()
  vim.fn.chdir(worktree_path)
  local status = vim.fn.system('git status --porcelain')
  vim.fn.chdir(cwd)

  if status ~= '' then
    -- Show confirmation for dirty worktree
    vim.ui.select(
      { 'Cancel', 'Delete anyway (LOSE CHANGES)' },
      {
        prompt = 'Worktree has uncommitted changes:',
        format_item = function(item)
          return item
        end,
      },
      function(choice)
        if choice == 'Delete anyway (LOSE CHANGES)' then
          M.do_delete_worktree(worktree_path)
        end
      end
    )
  else
    -- Clean worktree, confirm deletion
    vim.ui.select(
      { 'Cancel', 'Delete' },
      {
        prompt = 'Delete worktree: ' .. worktree_path,
        format_item = function(item)
          return item
        end,
      },
      function(choice)
        if choice == 'Delete' then
          M.do_delete_worktree(worktree_path)
        end
      end
    )
  end
end

---Actually delete the worktree
---@param worktree_path string Path to delete
function M.do_delete_worktree(worktree_path)
  local output = vim.fn.system('git worktree remove ' .. vim.fn.shellescape(worktree_path) .. ' --force')

  if vim.v.shell_error ~= 0 then
    vim.notify('Failed to delete worktree:\n' .. output, vim.log.levels.ERROR)
  else
    vim.notify('Deleted worktree: ' .. worktree_path, vim.log.levels.INFO)

    -- Clean up state
    local state = M.load_state()
    state[worktree_path] = nil
    M.save_state(state)
  end
end

---Switch to (or create) a worktree for a Bitbucket/GitHub PR via worktrunk
---@param pr_number string|number PR number (without "pr:" prefix; passed verbatim to worktrunk)
function M.switch_to_pr(pr_number)
  if vim.fn.executable('git-wt') ~= 1 then
    vim.notify('worktrunk (git-wt) is not installed. Run: brew install worktrunk', vim.log.levels.ERROR)
    return
  end

  local pr_arg = 'pr:' .. tostring(pr_number)
  vim.notify('Fetching PR ' .. pr_arg .. ' via worktrunk...', vim.log.levels.INFO)

  local decoded, err_kind, err_text = M._worktrunk_json({ 'switch', pr_arg })
  if not decoded then
    if err_kind == 'shell_error' then
      vim.notify('git-wt switch failed:\n' .. (err_text or ''), vim.log.levels.ERROR)
    elseif err_kind == 'decode' then
      vim.notify('Failed to parse git-wt JSON output:\n' .. (err_text or ''), vim.log.levels.ERROR)
    end
    return
  end

  local target_path = decoded.path or (decoded.worktree and decoded.worktree.path)
  if not target_path or vim.fn.isdirectory(target_path) ~= 1 then
    vim.notify('git-wt did not return a valid worktree path. Output:\n' .. vim.inspect(decoded), vim.log.levels.ERROR)
    return
  end

  M.switch_to_worktree(target_path)
end

---Prompt for a PR number and switch to its worktree via worktrunk
function M.pick_pr_and_switch()
  vim.ui.input({ prompt = 'PR number: ' }, function(input)
    if not input or input == '' then
      return
    end
    local pr_number = input:match('^%s*#?(%d+)%s*$')
    if not pr_number then
      vim.notify('Invalid PR number: ' .. tostring(input), vim.log.levels.WARN)
      return
    end
    M.switch_to_pr(pr_number)
  end)
end

---Generate dashboard section for current worktree
---@return table[]|nil Array of dashboard section descriptors or nil if no worktrees
function M.dashboard_section()
  local worktrees = M.list_worktrees()
  if not worktrees or #worktrees == 0 then
    return nil
  end

  local current = vim.tbl_filter(function(wt)
    return wt.is_current
  end, worktrees)[1]

  if not current then
    return nil
  end

  local status = M.get_worktree_status(current.path)
  local status_icon = status.clean and '\u{2713}' or '\u{26A0}'
  local status_text = status.clean and 'clean' or 'dirty'

  local ahead_behind = ''
  if status.ahead > 0 then
    ahead_behind = ahead_behind .. ' \u{2191}' .. status.ahead
  end
  if status.behind > 0 then
    ahead_behind = ahead_behind .. ' \u{2193}' .. status.behind
  end

  local items = {}

  -- Title
  table.insert(items, {
    text = {
      { '  ', hl = 'SnacksDashboardIcon' },
      { 'Git Worktree', hl = 'SnacksDashboardTitle' },
    },
    padding = 1,
  })

  -- Current worktree info
  local branch_display = current.branch_name or 'detached'
  table.insert(items, {
    text = {
      { '  ', width = 2 },
      { branch_display, hl = 'SnacksDashboardDesc' },
      {
        '  [' .. status_icon .. ' ' .. status_text .. ']',
        hl = status.clean and 'SnacksDashboardSpecial' or 'SnacksDashboardFooter',
      },
      { ahead_behind, hl = 'SnacksDashboardKey' },
    },
  })

  -- Other worktrees, if any
  local others = vim.tbl_filter(function(wt)
    return not wt.is_current
  end, worktrees)

  if #others > 0 then
    table.insert(items, {
      text = {
        { '  ', width = 2 },
        { 'Other: ' .. #others .. ' active', hl = 'SnacksDashboardFooter' },
      },
    })

    for _, wt in ipairs(vim.list_slice(others, 1, 3)) do
      local branch = wt.branch_name or 'unknown'
      table.insert(items, {
        text = {
          { '    \u{2022} ', hl = 'SnacksDashboardFooter' },
          { branch, hl = 'SnacksDashboardFooter' },
        },
      })
    end

    if #others > 3 then
      table.insert(items, {
        text = {
          { '    \u{2022} ', hl = 'SnacksDashboardFooter' },
          { '...and ' .. (#others - 3) .. ' more', hl = 'SnacksDashboardFooter' },
        },
      })
    end
  end

  -- Keybinding hint
  table.insert(items, {
    text = {
      { '  ', width = 2 },
      { '<leader>gw', hl = 'SnacksDashboardKey' },
      { ' to switch', hl = 'SnacksDashboardFooter' },
    },
    padding = 1,
  })

  return items
end

return M
