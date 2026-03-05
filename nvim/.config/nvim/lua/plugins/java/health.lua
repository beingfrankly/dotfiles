-- Health check module for Java development environment (nvim-java)
-- nvim-java manages JDTLS, Lombok, debug adapters, and test runners internally

local M = {}

-- Helper function to check if a directory exists
local function dir_exists(path)
  local expanded = vim.fn.expand(path)
  return vim.fn.isdirectory(expanded) == 1
end

-- Helper function to check if a file exists
local function file_exists(path)
  local expanded = vim.fn.expand(path)
  return vim.fn.filereadable(expanded) == 1
end

-- Helper function to parse Java version from java -version output
local function parse_java_version(version_output)
  -- Try to match version string like "21.0.7" or "1.8.0_282"
  local version = version_output:match('"([%d%.]+)')
  if version then
    -- Extract major version
    local major = version:match('^(%d+)')
    if major then
      return tonumber(major), version
    end
  end
  return nil, nil
end

-- Create the health check namespace
M.check = function()
  vim.health.start('Java Development Environment (nvim-java)')

  -- Check nvim-java is loaded
  local java_ok = pcall(require, 'java')
  if java_ok then
    vim.health.ok('nvim-java is loaded')
  else
    vim.health.error('nvim-java is not loaded', {
      'Ensure nvim-java/nvim-java is installed via lazy.nvim',
      'Check :Lazy for installation status',
    })
  end

  -- Check Java runtime
  local java_check = vim.fn.system('java -version 2>&1')
  local java_available = vim.v.shell_error == 0

  if not java_available then
    vim.health.error(
      'Java runtime not found',
      {
        'JDTLS requires Java 17 or newer',
        'Install Java via ASDF: asdf plugin add java && asdf install java corretto-21.0.7.6.1',
        'Or install via Homebrew: brew install openjdk@21',
      }
    )
  else
    local major_version, full_version = parse_java_version(java_check)
    if major_version and full_version then
      if major_version < 17 then
        vim.health.warn(
          'Java version ' .. full_version .. ' found (Java ' .. major_version .. ')',
          {
            'JDTLS requires Java 17 or newer',
            'Current version may cause issues',
            'Upgrade Java: asdf install java corretto-21.0.7.6.1',
          }
        )
      else
        vim.health.ok('Java runtime found: version ' .. full_version .. ' (Java ' .. major_version .. ')')
      end
    else
      vim.health.warn('Java found but version could not be determined', { 'Output: ' .. java_check:gsub('\n', ' ') })
    end
  end

  -- Check Maven
  local mvn_version = vim.fn.system('mvn -version 2>&1')
  local mvn_available = vim.v.shell_error == 0

  -- Special case: asdf reports "No version is set" with non-zero exit code
  local asdf_not_configured = mvn_version:match('No version is set')

  if asdf_not_configured then
    vim.health.warn(
      'Maven found but no version is configured (ASDF)',
      {
        'Set a Maven version with ASDF:',
        '  asdf install maven 3.9.9',
        '  asdf global maven 3.9.9',
        'Or create .tool-versions in your project root',
      }
    )
  elseif not mvn_available then
    vim.health.error(
      'Maven not found',
      {
        'Maven is required for building Java projects',
        'Install via ASDF: asdf plugin add maven && asdf install maven 3.9.9',
        'Or install via Homebrew: brew install maven',
      }
    )
  else
    -- Parse Maven version and home from output
    local version_line = mvn_version:match('Apache Maven ([%d%.]+)')
    local home_line = mvn_version:match('Maven home: ([^\n]+)')

    if version_line then
      vim.health.ok('Maven found: version ' .. version_line)
      if home_line then
        vim.health.info('Maven home: ' .. home_line)
      end
    else
      vim.health.warn('Maven found but version could not be determined', { 'Output: ' .. mvn_version:gsub('\n', ' ') })
    end
  end

  -- Check JDTLS workspace directory
  local home = vim.env.HOME or os.getenv('HOME')
  local workspace_base = home .. '/.local/share/nvim/jdtls-workspace/'

  -- Try to determine current project workspace
  local root_markers = { '.git', 'mvnw', 'pom.xml' }
  local root_dir = vim.fs.root(0, root_markers)
  local project_name = nil
  local workspace_dir = nil

  if root_dir then
    project_name = vim.fn.fnamemodify(root_dir, ':t')
    workspace_dir = workspace_base .. project_name
  else
    -- Fallback to current working directory
    project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
    workspace_dir = workspace_base .. project_name
  end

  if dir_exists(workspace_dir) then
    -- Get workspace size
    local du_cmd = 'du -sh ' .. vim.fn.shellescape(workspace_dir) .. ' 2>/dev/null'
    local size_output = vim.fn.system(du_cmd)
    local size = size_output:match('^(%S+)')

    vim.health.info('Workspace directory: ' .. workspace_dir)
    if size then
      vim.health.info('Workspace size: ' .. size)
    end

    -- Warn if workspace is very large (> 500MB)
    if size and size:match('(%d+)G') then
      vim.health.warn(
        'Workspace is very large (' .. size .. ')',
        {
          'Large workspaces can slow down JDTLS startup',
          'Consider cleaning up: rm -rf ' .. workspace_dir,
          'JDTLS will recreate it on next startup',
        }
      )
    end
  else
    vim.health.info('Workspace directory does not exist yet: ' .. workspace_dir)
    vim.health.info('JDTLS will create it on first Java file open')
  end

  -- Check MapStruct + Lombok binding (context-dependent)
  local cwd = vim.fn.getcwd()
  local pom_path = nil

  local pom_candidates = {
    cwd .. '/pom.xml',
  }

  local pom_root = vim.fs.root(0, { '.git', 'mvnw', 'pom.xml' })
  if pom_root then
    table.insert(pom_candidates, pom_root .. '/pom.xml')
  end

  for _, path in ipairs(pom_candidates) do
    if file_exists(path) then
      pom_path = path
      break
    end
  end

  if pom_path then
    -- Read pom.xml and check for MapStruct and lombok-mapstruct-binding
    local pom_content = vim.fn.readfile(pom_path)
    local pom_text = table.concat(pom_content, '\n')

    local has_mapstruct = pom_text:match('mapstruct') ~= nil
    local has_lombok_mapstruct_binding = pom_text:match('lombok%-mapstruct%-binding') ~= nil

    if has_mapstruct then
      if has_lombok_mapstruct_binding then
        vim.health.ok('MapStruct detected with lombok-mapstruct-binding dependency')

        local project_dir = vim.fn.fnamemodify(pom_path, ':h')
        local generated_sources = project_dir .. '/target/generated-sources/annotations'

        if dir_exists(generated_sources) then
          vim.health.info('Generated sources directory exists: ' .. generated_sources)
        else
          vim.health.info(
            'Generated sources directory not found (run mvn compile to generate): ' .. generated_sources
          )
        end

        vim.health.info('Ensure Lombok is declared BEFORE MapStruct in annotation processor order')
      else
        vim.health.warn(
          'MapStruct detected but lombok-mapstruct-binding is missing',
          {
            'When using both Lombok and MapStruct, the lombok-mapstruct-binding is required',
            'Add to your pom.xml <dependencies>:',
            '  <dependency>',
            '    <groupId>org.projectlombok</groupId>',
            '    <artifactId>lombok-mapstruct-binding</artifactId>',
            '    <version>0.2.0</version>',
            '  </dependency>',
            'Important: Lombok must be declared BEFORE MapStruct in annotation processor order',
          }
        )
      end
    end
  else
    vim.health.info('No pom.xml found in current directory - skipping MapStruct check')
  end

  -- Info about nvim-java managed components
  vim.health.info('JDTLS, Lombok, java-debug, java-test are managed by nvim-java (not Mason)')
end

return M
