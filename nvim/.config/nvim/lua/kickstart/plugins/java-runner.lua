---@diagnostic disable: undefined-global
local M = {}
local uv = vim.uv

-- ==== Config ====
local options = {
  -- File patterns that indicate a Spring Boot application
  spring_boot_indicators = {
    '*Application.java',
  },
  -- Directories to ignore
  ignore_dirs = {
    'node_modules',
    '.git',
    'dist',
    'build',
    'target',
    '.next',
    '.vscode',
    '.idea',
    'test',
    'tests',
  },
  -- Default Spring profile (can be overridden)
  default_profile = 'local', -- or 'dev', 'test', etc.
  -- Additional Maven arguments
  maven_args = '',
  -- Environment variables to pass to the application
  env_vars = {},
}

-- ==== Utils ====
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

local function get_repo_name(root)
  return vim.fn.fnamemodify(root, ':t')
end

local function should_ignore(dir_name)
  return vim.tbl_contains(options.ignore_dirs, dir_name) or dir_name:match '^%.'
end

local function find_spring_boot_apps(root)
  local apps = {}

  -- Use fd to find all Spring Boot Application files
  local cmd = string.format(
    'fd -t f -e java "%s" "%s" --exclude target --exclude build --exclude test --exclude tests',
    '.*Application\\.java$',
    root
  )

  local handle = io.popen(cmd)
  if not handle then
    Snacks.notify.error('Failed to search for Spring Boot applications')
    return apps
  end

  local result = handle:read('*a')
  handle:close()

  -- Parse results
  for line in result:gmatch('[^\r\n]+') do
    -- Extract module name and app name
    local module = line:match('/([^/]+)/src/main/java/')
    local app_file = line:match('([^/]+)%.java$')

    if module and app_file then
      -- Read the file to check for @SpringBootApplication annotation
      local file = io.open(line, 'r')
      if file then
        local content = file:read('*a')
        file:close()

        if content:match('@SpringBootApplication') then
          table.insert(apps, {
            name = app_file,
            module = module,
            path = line,
            display_name = module .. ' (' .. app_file .. ')',
          })
        end
      end
    end
  end

  -- Sort by module name
  table.sort(apps, function(a, b)
    return a.module < b.module
  end)

  return apps
end

local function run_spring_boot_app(app, profile)
  local root = find_git_root()
  if not root then
    Snacks.notify.error('Not in a git repository')
    return
  end

  -- Use provided profile or default
  local active_profile = profile or options.default_profile

  -- Build the Maven command to run the Spring Boot application
  -- Use -pl to specify the module and spring-boot:run to start it
  local cmd_parts = {
    'cd "' .. root .. '"',
    '&&',
    'mvn',
    '-pl ' .. app.module,
    'spring-boot:run',
  }

  -- Add Spring profile as system property
  if active_profile and active_profile ~= '' then
    table.insert(cmd_parts, '-Dspring-boot.run.profiles=' .. active_profile)
  end

  -- Add any additional Maven arguments
  if options.maven_args and options.maven_args ~= '' then
    table.insert(cmd_parts, options.maven_args)
  end

  local cmd = table.concat(cmd_parts, ' ')

  -- Merge environment variables
  local env = vim.tbl_extend('force', {
    TERM = vim.env.TERM or 'xterm-256color',
  }, options.env_vars or {})

  -- Open in Snacks terminal
  Snacks.terminal(cmd, {
    cwd = root,
    win = {
      position = 'float',
      width = 0.9,
      height = 0.9,
      border = 'rounded',
      title = '  Running: ' .. app.display_name .. ' [' .. (active_profile or 'default') .. '] ',
      title_pos = 'center',
    },
    env = env,
  })

  Snacks.notify.info('Starting ' .. app.display_name .. ' with profile: ' .. (active_profile or 'default'))
end

-- ==== Main Functions ====
function M.setup(opts)
  -- Merge options
  options = vim.tbl_deep_extend('force', options, opts or {})
end

function M.select_and_run()
  local root = find_git_root()
  if not root then
    Snacks.notify.error('Not in a git repository')
    return
  end

  Snacks.notify.info('Searching for Spring Boot applications...')

  local apps = find_spring_boot_apps(root)
  if #apps == 0 then
    Snacks.notify.warn('No Spring Boot applications found in ' .. root)
    return
  end

  -- Create items for the picker
  local items = {}
  local longest_name = 0
  for i, app in ipairs(apps) do
    table.insert(items, {
      idx = i,
      score = i,
      text = app.path,
      name = app.module,
      app = app,
    })
    longest_name = math.max(longest_name, #app.module)
  end
  longest_name = longest_name + 2

  local repo_name = get_repo_name(root)

  -- Use Snacks picker
  local picker_opts = {
    items = items,
    title = 'Run Spring Boot App: ' .. repo_name,
    focus = 'list',
    format = function(item)
      return { { item.app.display_name, 'SnacksPickerLabel' } }
    end,
    layout = {
      preset = 'vscode',
      preview = false,
    },
    confirm = function(picker, item)
      if item then
        run_spring_boot_app(item.app)
      end
      picker:close()
    end,
  }

  Snacks.picker(picker_opts)
end

return M
