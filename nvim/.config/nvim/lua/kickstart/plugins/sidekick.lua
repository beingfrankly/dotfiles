-- sidekick.nvim: AI CLI sessions (Claude Code, Codex) inside Neovim
-- https://github.com/folke/sidekick.nvim
--
-- CLI-only setup (NES/Next Edit Suggestion is disabled).
-- Uses zellij as multiplexer so AI sessions persist across nvim restarts.

local sidekick = require('kickstart.util').try_require('sidekick', 'sidekick.nvim')
if not sidekick then return end

sidekick.setup({
  cli = {
    watch = true,
    mux = {
      backend = 'zellij',
      enabled = true,
    },
    -- Override only the built-in claude tool to always start with the
    -- orchestrator agent. Other tools (e.g. codex) keep their defaults.
    tools = {
      claude = { cmd = { 'claude', '--agent', 'orchestrator' }, url = 'https://github.com/anthropics/claude-code' },
    },
  },
  nes = {
    enabled = false,
  },
})

local cli = require('sidekick.cli')

-- Cooperative state for the lualine indicator: flipped only by the named
-- tool keymaps below (<leader>ac, <leader>ax). The generic <leader>aa
-- toggle does NOT update this, so the indicator may drift if a session is
-- opened/closed without the named binding. See lualine.lua for the reader.
local function toggle_tool(name)
  return function()
    cli.toggle({ name = name, focus = true })
    if vim.g.sidekick_active == name then
      vim.g.sidekick_active = nil
    else
      vim.g.sidekick_active = name
    end
  end
end

-- Toggle the active CLI window (or last-used tool)
vim.keymap.set({ 'n', 'v' }, '<leader>aa', function()
  cli.toggle({ focus = true })
end, { desc = 'Sidekick: toggle CLI' })

-- Toggle Claude Code session
vim.keymap.set({ 'n', 'v' }, '<leader>ac', toggle_tool('claude'), { desc = 'Sidekick: Claude' })

-- Toggle Codex session
vim.keymap.set({ 'n', 'v' }, '<leader>ax', toggle_tool('codex'), { desc = 'Sidekick: Codex' })

-- Pick a CLI tool from the installed list
vim.keymap.set('n', '<leader>as', function()
  cli.select()
end, { desc = 'Sidekick: select CLI tool' })

-- Insert a predefined prompt template into the active session
vim.keymap.set({ 'n', 'v' }, '<leader>ap', function()
  cli.prompt()
end, { desc = 'Sidekick: prompt' })

-- Toggle focus between editor and CLI window
vim.keymap.set({ 'n', 'x', 'i', 't' }, '<C-.>', function()
  cli.focus()
end, { desc = 'Sidekick: focus' })
