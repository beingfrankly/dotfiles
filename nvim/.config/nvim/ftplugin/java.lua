-- Java filetype configuration
-- Snacks terminal testing + nvim-java command keymaps

-- Helper function to get the test class name from the current file
local function get_test_class_name()
  local filepath = vim.fn.expand('%:p')
  -- Extract class name from file path (e.g., src/test/java/com/example/MyTest.java -> com.example.MyTest)
  local class_path = filepath:match('src/test/java/(.+)%.java$') or filepath:match('src/main/java/(.+)%.java$')
  if class_path then
    return class_path:gsub('/', '.')
  end
  return vim.fn.expand('%:t:r') -- Fallback to filename without extension
end

-- Helper function to get the current test method name using treesitter
local function get_test_method_name()
  local ok, ts_utils = pcall(require, 'nvim-treesitter.ts_utils')
  if not ok then
    vim.notify('nvim-treesitter not available', vim.log.levels.WARN)
    return nil
  end

  local node = ts_utils.get_node_at_cursor()
  while node do
    if node:type() == 'method_declaration' then
      local name_node = node:field('name')[1]
      if name_node then
        return vim.treesitter.get_node_text(name_node, 0)
      end
    end
    node = node:parent()
  end
  return nil
end

-- Detect build tool (Maven or Gradle)
local function detect_build_tool()
  local root_dir = vim.fs.root(0, { 'pom.xml', 'build.gradle', 'build.gradle.kts', '.git' })
  if not root_dir then
    return nil, vim.fn.getcwd()
  end

  if vim.fn.filereadable(root_dir .. '/pom.xml') == 1 then
    return 'maven', root_dir
  elseif vim.fn.filereadable(root_dir .. '/build.gradle') == 1 or vim.fn.filereadable(root_dir .. '/build.gradle.kts') == 1 then
    return 'gradle', root_dir
  end

  return nil, root_dir
end

-- Run test with Maven or Gradle
local function run_test(scope)
  local ok, Snacks = pcall(require, 'snacks')
  if not ok then
    vim.notify('snacks.nvim not available', vim.log.levels.ERROR)
    return
  end

  local build_tool, root_dir = detect_build_tool()
  local class_name = get_test_class_name()
  local cmd

  if build_tool == 'maven' then
    if scope == 'class' then
      cmd = string.format('mvn test -Dtest=%s', class_name)
    elseif scope == 'method' then
      local method = get_test_method_name()
      if method then
        cmd = string.format('mvn test -Dtest=%s#%s', class_name, method)
      else
        vim.notify('Could not find test method at cursor', vim.log.levels.WARN)
        return
      end
    end
  elseif build_tool == 'gradle' then
    if scope == 'class' then
      cmd = string.format('./gradlew test --tests %s', class_name)
    elseif scope == 'method' then
      local method = get_test_method_name()
      if method then
        cmd = string.format('./gradlew test --tests %s.%s', class_name, method)
      else
        vim.notify('Could not find test method at cursor', vim.log.levels.WARN)
        return
      end
    end
  else
    vim.notify('No Maven (pom.xml) or Gradle (build.gradle) found in project', vim.log.levels.ERROR)
    return
  end

  Snacks.terminal.open(cmd, {
    cwd = root_dir,
    win = {
      position = 'float',
      width = 0.9,
      height = 0.8,
      border = 'rounded',
      title = '  Running: ' .. scope .. ' test ',
      title_pos = 'center',
    },
  })
end

-- Run current Spring Boot application in debug mode
local function run_debug_app()
  local ok, Snacks = pcall(require, 'snacks')
  if not ok then
    vim.notify('snacks.nvim not available', vim.log.levels.ERROR)
    return
  end

  local build_tool, root_dir = detect_build_tool()
  local cmd

  if build_tool == 'maven' then
    cmd = 'mvn spring-boot:run -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005"'
  elseif build_tool == 'gradle' then
    cmd = './gradlew bootRun --debug-jvm'
  else
    vim.notify('No Maven (pom.xml) or Gradle (build.gradle) found in project', vim.log.levels.ERROR)
    return
  end

  Snacks.terminal.open(cmd, {
    cwd = root_dir,
    win = {
      position = 'float',
      width = 0.9,
      height = 0.8,
      border = 'rounded',
      title = '  Spring Boot (Debug Mode - Port 5005) ',
      title_pos = 'center',
    },
  })

  vim.notify('App starting with debug port 5005. Use <leader>dc to attach debugger.', vim.log.levels.INFO)
end

-- Compile current Maven module
local function maven_compile()
  local ok, Snacks = pcall(require, 'snacks')
  if not ok then
    vim.notify('snacks.nvim not available', vim.log.levels.ERROR)
    return
  end

  local build_tool, root_dir = detect_build_tool()

  if build_tool ~= 'maven' then
    vim.notify('Maven compile only works with Maven projects', vim.log.levels.WARN)
    return
  end

  Snacks.terminal.open('mvn compile -DskipTests', {
    cwd = root_dir,
    win = {
      position = 'float',
      width = 0.9,
      height = 0.6,
      border = 'rounded',
      title = '  Maven Compile ',
      title_pos = 'center',
    },
  })
end

-- Keybindings
local opts = { buffer = true, silent = true }

-- Snacks terminal test running
vim.keymap.set('n', '<leader>tc', function()
  run_test('class')
end, vim.tbl_extend('force', opts, { desc = '[T]est [C]lass (Maven/Gradle)' }))

vim.keymap.set('n', '<leader>tm', function()
  run_test('method')
end, vim.tbl_extend('force', opts, { desc = '[T]est [M]ethod (Maven/Gradle)' }))

-- Build commands
vim.keymap.set('n', '<leader>jc', maven_compile, vim.tbl_extend('force', opts, { desc = '[J]ava [C]ompile (Maven)' }))

-- Debug commands
vim.keymap.set(
  'n',
  '<leader>jd',
  run_debug_app,
  vim.tbl_extend('force', opts, { desc = '[J]ava [D]ebug (Start app with debug port)' })
)

-- nvim-java: Refactoring
vim.keymap.set('n', '<leader>jv', '<Cmd>JavaRefactorExtractVariable<CR>', vim.tbl_extend('force', opts, { desc = '[J]ava Extract [V]ariable' }))
vim.keymap.set('n', '<leader>jV', '<Cmd>JavaRefactorExtractVariableAllOccurrence<CR>', vim.tbl_extend('force', opts, { desc = '[J]ava Extract [V]ariable (all occurrences)' }))
vim.keymap.set('n', '<leader>jk', '<Cmd>JavaRefactorExtractConstant<CR>', vim.tbl_extend('force', opts, { desc = '[J]ava Extract [K]onstant' }))
vim.keymap.set('v', '<leader>jm', '<Cmd>JavaRefactorExtractMethod<CR>', vim.tbl_extend('force', opts, { desc = '[J]ava Extract [M]ethod' }))
vim.keymap.set('n', '<leader>jf', '<Cmd>JavaRefactorExtractField<CR>', vim.tbl_extend('force', opts, { desc = '[J]ava Extract [F]ield' }))

-- nvim-java: Test running (via DAP)
vim.keymap.set('n', '<leader>jtc', '<Cmd>JavaTestRunCurrentClass<CR>', vim.tbl_extend('force', opts, { desc = '[J]ava [T]est [C]lass (DAP)' }))
vim.keymap.set('n', '<leader>jtm', '<Cmd>JavaTestRunCurrentMethod<CR>', vim.tbl_extend('force', opts, { desc = '[J]ava [T]est [M]ethod (DAP)' }))
vim.keymap.set('n', '<leader>jta', '<Cmd>JavaTestRunAllTests<CR>', vim.tbl_extend('force', opts, { desc = '[J]ava [T]est [A]ll' }))
vim.keymap.set('n', '<leader>jtr', '<Cmd>JavaTestViewLastReport<CR>', vim.tbl_extend('force', opts, { desc = '[J]ava [T]est [R]eport' }))
vim.keymap.set('n', '<leader>jtC', '<Cmd>JavaTestDebugCurrentClass<CR>', vim.tbl_extend('force', opts, { desc = '[J]ava [T]est Debug [C]lass (DAP)' }))
vim.keymap.set('n', '<leader>jtM', '<Cmd>JavaTestDebugCurrentMethod<CR>', vim.tbl_extend('force', opts, { desc = '[J]ava [T]est Debug [M]ethod (DAP)' }))

-- nvim-java: Run/Stop
vim.keymap.set('n', '<leader>jr', '<Cmd>JavaRunnerRunMain<CR>', vim.tbl_extend('force', opts, { desc = '[J]ava [R]un main class' }))
vim.keymap.set('n', '<leader>js', '<Cmd>JavaRunnerStopMain<CR>', vim.tbl_extend('force', opts, { desc = '[J]ava [S]top running app' }))
vim.keymap.set('n', '<leader>jl', '<Cmd>JavaRunnerToggleLogs<CR>', vim.tbl_extend('force', opts, { desc = '[J]ava Runner [L]ogs toggle' }))

-- nvim-java: Build workspace
vim.keymap.set('n', '<leader>jb', '<Cmd>JavaBuildBuildWorkspace<CR>', vim.tbl_extend('force', opts, { desc = '[J]ava [B]uild workspace' }))
vim.keymap.set('n', '<leader>jB', '<Cmd>JavaBuildCleanWorkspace<CR>', vim.tbl_extend('force', opts, { desc = '[J]ava Clean [B]uild workspace' }))

-- nvim-java: Profile & Runtime management
vim.keymap.set('n', '<leader>jp', '<Cmd>JavaProfile<CR>', vim.tbl_extend('force', opts, { desc = '[J]ava [P]rofile management' }))
vim.keymap.set('n', '<leader>jR', '<Cmd>JavaSettingsChangeRuntime<CR>', vim.tbl_extend('force', opts, { desc = '[J]ava Change [R]untime' }))
