-- Shared utilities for kickstart plugin modules.

local M = {}

--- Require a module, warning once on failure.
--- @param name string module name passed to require()
--- @param display string|nil display name used in the warn message (defaults to name)
--- @return any|nil module table, or nil if the require failed
function M.try_require(name, display)
  local ok, mod = pcall(require, name)
  if not ok then
    vim.notify((display or name) .. ' not installed', vim.log.levels.WARN)
    return nil
  end
  return mod
end

return M
