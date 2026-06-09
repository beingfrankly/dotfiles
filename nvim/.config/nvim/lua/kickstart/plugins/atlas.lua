-- atlas.nvim: PRs + Jira issues inside Neovim
-- https://github.com/emrearmagan/atlas.nvim
--
-- Enabled providers: Bitbucket pulls + Jira issues (Striive workflow).
--
-- CONFIGURATION:
--   Non-secrets (env vars, fine to keep in ~/.zshrc):
--     JIRA_URL         e.g. https://your-company.atlassian.net
--     JIRA_EMAIL       your Atlassian account email
--     BITBUCKET_USER   your Bitbucket username (the user, not the email)
--
--   Secrets (preferred: macOS Keychain; env vars are a fallback):
--     BITBUCKET_TOKEN  Atlassian API token; keychain service: jira_api_token
--     JIRA_TOKEN       Atlassian API token; keychain service: jira_api_token
--                      https://id.atlassian.com/manage-profile/security/api-tokens
--                      Atlassian unified its API tokens across Jira Cloud +
--                      Bitbucket Cloud in 2025, so a single keychain entry
--                      backs both. (App passwords are deprecated.)
--
-- One-time keychain bootstrap (mac):
--   security add-generic-password -s jira_api_token -w '<token>' -U
--
-- If a token is missing from BOTH keychain and env, atlas still loads — authentication
-- will fail at the first :AtlasIssues / :AtlasPulls invocation. Nothing here crashes nvim.
--
-- PR diffs are rendered by diffview.nvim (see kickstart.plugins.diffview).

local atlas = require('kickstart.util').try_require('atlas', 'atlas.nvim')
if not atlas then return end

--- Look up a secret from macOS Keychain by service name. Returns nil on non-mac,
--- missing entry, or locked keychain (the `security` CLI exits non-zero on all three).
--- The account (-a) is intentionally not constrained so any account under the given
--- service matches — useful for entries created without an explicit -a flag.
--- @param service string keychain service name (e.g., 'jira_api_token')
--- @return string|nil token  password string, or nil on any failure
local function keychain(service)
  if vim.fn.has('mac') ~= 1 then
    return nil
  end
  local out = vim.fn.systemlist({ 'security', 'find-generic-password', '-s', service, '-w' })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return out[1]
end

atlas.setup({
  pulls = {
    diff = {
      open_cmd = 'DiffviewOpen',
    },
    providers = {
      bitbucket = {
        user = vim.env.BITBUCKET_USER or '',
        token = keychain('jira_api_token') or vim.env.BITBUCKET_TOKEN or '',
        cache_ttl = 300,
      },
    },
  },
  issues = {
    max_results = 100,
    with_relationships = true,
    providers = {
      jira = {
        base_url = vim.env.JIRA_URL or '',
        email = vim.env.JIRA_EMAIL or '',
        token = keychain('jira_api_token') or vim.env.JIRA_TOKEN or '',
        cache_ttl = 300,
        -- atlas requires at least one view with a JQL string; without one the
        -- provider returns "Missing Jira view JQL" and the picker is empty.
        -- First entry is the default view; <Tab>/<S-Tab> cycle between them.
        views = {
          {
            name = 'My open II',
            jql = 'project = II AND assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC',
          },
          {
            name = 'Sprint II',
            jql = 'project = II AND sprint in openSprints() ORDER BY rank ASC',
          },
        },
      },
    },
  },
})

-- Cooperative state for the lualine indicator: flipped only by the named
-- open keymaps below (<leader>jj, <leader>Pp). Other entry points like
-- direct :AtlasIssues / :AtlasPulls invocation do NOT update this, so the
-- indicator may drift. See lualine.lua for the reader.
--
-- atlas.nvim has no close-command, so a second press of the same key must
-- NOT re-run the open command (that would stack a second panel). Instead,
-- we treat the second press as "I'm done looking at this" and clear the
-- indicator only; the user closes the actual buffer via :bdelete / <C-w>q.
local function open_atlas(cmd, label)
  return function()
    if vim.g.atlas_active == label then
      vim.g.atlas_active = nil
      return
    end
    vim.cmd(cmd)
    vim.g.atlas_active = label
  end
end

-- Issues (Jira) keymaps under <leader>j*
vim.keymap.set('n', '<leader>jj', function()
  require('lib.jira_picker').open()
end, { desc = 'Jira issues (custom picker)' })
vim.keymap.set('n', '<leader>jc', '<cmd>AtlasCreateIssue<cr>', { desc = 'Atlas: create issue' })
vim.keymap.set('n', '<leader>js', '<cmd>AtlasSearch jira<cr>', { desc = 'Atlas: Jira search' })

-- Pulls (Bitbucket) keymaps under <leader>P* (capital P; <leader>p* is the snacks profiler)
vim.keymap.set('n', '<leader>Pp', open_atlas('AtlasPulls bitbucket', 'Bitbucket Pulls'), { desc = 'Atlas: Bitbucket pulls' })
vim.keymap.set('n', '<leader>Pc', '<cmd>AtlasCreatePR<cr>', { desc = 'Atlas: create PR' })
vim.keymap.set('n', '<leader>Ps', '<cmd>AtlasSearch bitbucket<cr>', { desc = 'Atlas: Bitbucket search' })
