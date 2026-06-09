-- Diagnostic line highlight colors (subtle backgrounds)
local palette = {
  err = '#51202A',
  warn = '#3B3B1B',
  info = '#1F3342',
  hint = '#1E2E1E',
}

vim.api.nvim_set_hl(0, 'DiagnosticErrorLine', { bg = palette.err, blend = 20 })
vim.api.nvim_set_hl(0, 'DiagnosticWarnLine', { bg = palette.warn, blend = 15 })
vim.api.nvim_set_hl(0, 'DiagnosticInfoLine', { bg = palette.info, blend = 10 })
vim.api.nvim_set_hl(0, 'DiagnosticHintLine', { bg = palette.hint, blend = 10 })

-- DAP breakpoint sign
vim.api.nvim_set_hl(0, 'DapBreakpointSign', { fg = '#FF0000', bg = nil, bold = true })
vim.fn.sign_define('DapBreakpoint', {
  text = '●',
  texthl = 'DapBreakpointSign',
  linehl = '',
  numhl = '',
})

local sev = vim.diagnostic.severity

vim.diagnostic.config {
  underline = true,
  severity_sort = true,
  update_in_insert = false,
  float = {
    border = 'rounded',
    source = true,
  },
  signs = {
    text = {
      [sev.ERROR] = ' ',
      [sev.WARN] = ' ',
      [sev.INFO] = ' ',
      [sev.HINT] = '󰌵 ',
    },
  },
  virtual_text = false, -- using tiny-inline-diagnostic instead
  linehl = {
    [sev.ERROR] = 'DiagnosticErrorLine',
    [sev.WARN] = 'DiagnosticWarnLine',
    [sev.INFO] = 'DiagnosticInfoLine',
    [sev.HINT] = 'DiagnosticHintLine',
  },
}

-- Diagnostic navigation keymaps
local diagnostic_goto = function(next, severity)
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    vim.diagnostic.jump { count = next and 1 or -1, float = true, severity = severity }
  end
end

vim.keymap.set('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Line Diagnostics' })
vim.keymap.set('n', ']d', diagnostic_goto(true), { desc = 'Next Diagnostic' })
vim.keymap.set('n', '[d', diagnostic_goto(false), { desc = 'Prev Diagnostic' })
vim.keymap.set('n', ']e', diagnostic_goto(true, 'ERROR'), { desc = 'Next Error' })
vim.keymap.set('n', '[e', diagnostic_goto(false, 'ERROR'), { desc = 'Prev Error' })
vim.keymap.set('n', ']w', diagnostic_goto(true, 'WARN'), { desc = 'Next Warning' })
vim.keymap.set('n', '[w', diagnostic_goto(false, 'WARN'), { desc = 'Prev Warning' })

-- Tiny inline diagnostic plugin
require('tiny-inline-diagnostic').setup {
  preset = 'simple',
}
