-- Constants for Jest test runner plugin

local M = {}

-- Test file patterns
M.TEST_FILE_PATTERNS = {
  '%.spec%.ts$',
  '%.spec%.js$',
  '%.test%.ts$',
  '%.test%.js$',
  '%.spec%.tsx$',
  '%.spec%.jsx$',
  '%.test%.tsx$',
  '%.test%.jsx$',
}

-- Jest config file names (in priority order)
M.JEST_CONFIG_FILES = {
  'jest.config.ts',
  'jest.config.js',
  'jest.config.mjs',
  'jest.config.cjs',
  'jest.config.json',
}

-- Tree-sitter node types for test detection
M.TEST_NODE_TYPES = {
  CALL_EXPRESSION = 'call_expression',
}

-- Test function names recognized by Jest
M.TEST_FUNCTION_NAMES = {
  DESCRIBE = 'describe',
  IT = 'it',
  TEST = 'test',
}

-- Test result statuses from Jest JSON output
M.TEST_STATUS = {
  PASSED = 'passed',
  FAILED = 'failed',
  PENDING = 'pending',
  SKIPPED = 'skipped',
}

-- Visual indicators for test results
M.TEST_ICONS = {
  PASSED = '✓',
  FAILED = '✗',
  UNKNOWN = '?',
}

-- Highlight groups for test results
M.HIGHLIGHT_GROUPS = {
  PASSED = 'DiagnosticOk',
  FAILED = 'DiagnosticError',
  RUNNING = 'Comment',
  UNKNOWN = 'Comment',
}

-- Spinner animation frames for running tests
M.SPINNER_FRAMES = {
  '⠋',
  '⠙',
  '⠹',
  '⠸',
  '⠼',
  '⠴',
  '⠦',
  '⠧',
  '⠇',
  '⠏',
}

-- Spinner update interval in milliseconds
M.SPINNER_UPDATE_INTERVAL = 100

-- Jest watch mode patterns for detecting test runs
M.WATCH_MODE_PATTERNS = {
  'Determining test suites',
  'RUNS',
}

-- Default configuration values
M.DEFAULT_CONFIG = {
  jest_cmd = 'jest',
  split_direction = 'horizontal',
  split_size = 15,
  focus_after_run = false,
  auto_detect_config = true,
  use_virtual_text = true,
  show_split_on_error = true,
}

-- Valid configuration values
M.VALID_SPLIT_DIRECTIONS = {
  HORIZONTAL = 'horizontal',
  VERTICAL = 'vertical',
}

return M
