-- lib/jira.lua — Pure Lua Jira REST client for Atlassian Cloud.
-- No UI. Provides config(), search(), and get_issue() for use by lib/jira_picker.lua.
-- HTTP via plenary.curl (async callback mode). Auth: Basic (email:token).
-- Spec reference: docs/jira-picker-spec.md §6.1, §6.2, §8.

local M = {}

-- Default fields requested for search results.
local DEFAULT_FIELDS = {
  'summary', 'status', 'assignee', 'reporter', 'priority',
  'issuetype', 'labels', 'updated',
}

-- Fields for get_issue — includes description ADF on top of the defaults.
local GET_ISSUE_FIELDS = vim.list_extend({ 'description' }, DEFAULT_FIELDS)

-- Look up a secret from macOS Keychain by service name.
-- Returns nil on non-mac, missing entry, or locked keychain.
-- Copied verbatim from lua/kickstart/plugins/atlas.lua:37-46.
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

-- Build a single human-readable error string from a Jira error body.
-- Handles both errorMessages (array) and errors (field → msg map).
local function jira_error_string(decoded)
  local parts = {}
  if type(decoded.errorMessages) == 'table' then
    for _, msg in ipairs(decoded.errorMessages) do
      if type(msg) == 'string' and msg ~= '' then
        table.insert(parts, msg)
      end
    end
  end
  if type(decoded.errors) == 'table' then
    for field, msg in pairs(decoded.errors) do
      table.insert(parts, field .. ': ' .. tostring(msg))
    end
  end
  if #parts > 0 then
    return table.concat(parts, '; ')
  end
  return nil
end

-- Coerce vim.NIL (the userdata Neovim's JSON decoder returns for `null`)
-- to a real nil. Plain `or` guards do not catch vim.NIL — it is truthy —
-- which made `(f.assignee and f.assignee.displayName)` crash on
-- unassigned tickets when f.assignee == vim.NIL.
local function nz(v)
  if v == nil or v == vim.NIL then return nil end
  return v
end

-- Normalize a raw Jira issue object into the picker-friendly shape (§6.2).
local function normalize_issue(raw, base_url)
  local f = nz(raw.fields) or {}
  local status    = nz(f.status)
  local assignee  = nz(f.assignee)
  local reporter  = nz(f.reporter)
  local priority  = nz(f.priority)
  local issuetype = nz(f.issuetype)
  return {
    key       = raw.key,
    summary   = nz(f.summary) or '',
    status    = (status and nz(status.name)) or '',
    assignee  = assignee and nz(assignee.displayName) or nil,
    reporter  = reporter and nz(reporter.displayName) or nil,
    priority  = priority and nz(priority.name) or nil,
    issuetype = issuetype and nz(issuetype.name) or nil,
    labels    = nz(f.labels) or {},
    updated   = nz(f.updated),
    url       = base_url .. '/browse/' .. raw.key,
    description_adf = nz(f.description),
    _raw      = raw,
  }
end

-- Internal HTTP helper. Performs a GET or POST via plenary.curl (async).
-- Calls on_done(result_table, nil) on success or on_done(nil, err_string) on failure.
-- Returns a cancel() closure that discards the in-flight callback when called.
--
-- `cfg` MUST be a resolved config table (see M.config()). do_request does NOT
-- call M.config() itself — that would re-read env/keychain, which would crash
-- when invoked from the snacks finder coroutine (a libuv fast-event context).
-- Callers (M.search, M.get_issue) resolve cfg once at their entry point on
-- the main thread, then pass it through.
local function do_request(method, path, body_table, cfg, on_done)
  local auth = vim.base64.encode(string.format('%s:%s', cfg.email, cfg.token))
  local url = cfg.base_url .. '/rest/api/3' .. path

  local cancelled = false

  local function handle_response(response)
    if cancelled then
      return
    end

    -- Shell / network-level failure.
    if response.exit ~= 0 then
      on_done(nil, 'jira: curl exit ' .. tostring(response.exit))
      return
    end

    -- Decode body — guard against non-JSON error pages.
    local ok, decoded = pcall(vim.json.decode, response.body or '')
    if not ok then
      local status_hint = response.status and (' (HTTP ' .. tostring(response.status) .. ')') or ''
      on_done(nil, 'jira: failed to decode response body' .. status_hint)
      return
    end

    -- HTTP non-2xx.
    if response.status < 200 or response.status >= 300 then
      -- Try to surface the Jira error payload first.
      local jira_msg = type(decoded) == 'table' and jira_error_string(decoded)
      if jira_msg then
        on_done(nil, string.format('jira: HTTP %d: %s', response.status, jira_msg))
      else
        local body_preview = type(response.body) == 'string'
          and response.body:sub(1, 120)
          or ''
        on_done(nil, string.format('jira: HTTP %d: %s', response.status, body_preview))
      end
      return
    end

    -- 2xx with a Jira error body (e.g. 200 + errorMessages).
    if type(decoded) == 'table' then
      local jira_msg = jira_error_string(decoded)
      if jira_msg then
        on_done(nil, 'jira: ' .. jira_msg)
        return
      end
    end

    on_done(decoded, nil)
  end

  local opts = {
    url = url,
    headers = {
      Authorization = 'Basic ' .. auth,
      ['Content-Type'] = 'application/json',
      Accept = 'application/json',
    },
    callback = vim.schedule_wrap(handle_response),
    on_error = vim.schedule_wrap(function(error_info)
      if cancelled then
        return
      end
      on_done(nil, 'jira: curl error: ' .. (error_info.message or tostring(error_info.exit or '')))
    end),
  }

  if body_table then
    -- vim.json.encode is Lua-native; vim.fn.json_encode would crash here
    -- because do_request runs from the snacks finder coroutine, which is a
    -- libuv fast-event context where vimscript functions are forbidden.
    local encode_ok, encoded = pcall(vim.json.encode, body_table)
    if not encode_ok then
      on_done(nil, 'jira: failed to encode request body')
      return function() end
    end
    opts.body = encoded
  end

  local curl = require('plenary.curl')
  local job
  if method == 'GET' then
    job = curl.get(opts)
  elseif method == 'POST' then
    job = curl.post(opts)
  else
    on_done(nil, 'jira: unsupported HTTP method ' .. method)
    return function() end
  end

  return function()
    if cancelled then
      return
    end
    cancelled = true
    -- Attempt to kill the underlying process. plenary Job exposes .handle (a libuv handle).
    -- This is best-effort; if the job has already finished the pcall is a no-op.
    if job and job.handle then
      pcall(function() job.handle:kill(9) end)
    end
  end
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

-- Cache for resolved credentials. Populated on first successful main-thread
-- M.config() call. The snacks picker's finder runs in a libuv fast-event
-- context where `vim.env.*` (getenv) and `vim.fn.systemlist` (keychain) are
-- forbidden, so the cache lets later in-finder calls reuse the resolved
-- values without re-reading env/keychain. Cleared by M.invalidate_config().
local _cached_config = nil

--- Force the next M.config() call to re-read env + keychain.
--- Use after rotating the keychain token or changing JIRA_URL/JIRA_EMAIL
--- without restarting nvim.
function M.invalidate_config()
  _cached_config = nil
end

--- Resolve credentials from env + keychain.
--- Result is cached on first success; subsequent calls (including from fast
--- event contexts) return the cache without touching getenv/systemlist.
--- @return table|nil config  { base_url: string, email: string, token: string }
--- @return string|nil err
function M.config()
  if _cached_config then
    return _cached_config, nil
  end

  local base_url = vim.env.JIRA_URL
  if not base_url or base_url == '' then
    return nil, 'jira: set JIRA_URL (e.g. https://your-company.atlassian.net)'
  end
  -- Strip trailing slash so callers can safely concat /rest/api/3/...
  base_url = base_url:gsub('/$', '')

  local email = vim.env.JIRA_EMAIL
  if not email or email == '' then
    return nil, 'jira: set JIRA_EMAIL (your Atlassian account email)'
  end

  local token = keychain('jira_api_token') or vim.env.JIRA_TOKEN
  if not token or token == '' then
    return nil, 'jira: no API token — add jira_api_token to macOS Keychain or set JIRA_TOKEN'
  end

  _cached_config = { base_url = base_url, email = email, token = token }
  return _cached_config, nil
end

--- Async issue search.
--- @param jql string  raw JQL string
--- @param opts table?  { fields = string[]?, max_results = number?, page_token = string? }
--- @param on_done fun(issues: table[]|nil, err: string|nil, page: table|nil)
--- @return fun() cancel
function M.search(jql, opts, on_done)
  opts = opts or {}
  local fields = opts.fields or DEFAULT_FIELDS
  local max_results = opts.max_results or 50
  local page_token = opts.page_token or ''

  -- Resolve credentials once at entry. Used both for HTTP auth (passed
  -- through to do_request) and for normalize_issue's base_url. Caller
  -- contract: M.config() must succeed from the calling context — for the
  -- snacks picker that means M.open()'s main-thread preflight populates
  -- the cache so this call returns it without re-reading env/keychain.
  local cfg, cfg_err = M.config()
  if not cfg then
    on_done(nil, cfg_err, nil)
    return function() end
  end

  local body = {
    jql = jql,
    fields = fields,
    nextPageToken = page_token,
    maxResults = max_results,
  }

  return do_request('POST', '/search/jql', body, cfg, function(decoded, err)
    if err then
      on_done(nil, err, nil)
      return
    end

    local raw_issues = (type(decoded) == 'table' and decoded.issues) or {}
    local issues = vim.tbl_map(function(raw)
      return normalize_issue(raw, cfg.base_url)
    end, raw_issues)

    local page = {
      is_last = decoded.isLast == true,
      next_page_token = decoded.nextPageToken or nil,
    }

    on_done(issues, nil, page)
  end)
end

--- Async single-issue fetch (includes description ADF).
--- @param key string  e.g. 'II-1234'
--- @param on_done fun(issue: table|nil, err: string|nil)
--- @return fun() cancel
function M.get_issue(key, on_done)
  local fields_csv = table.concat(GET_ISSUE_FIELDS, ',')
  local path = '/issue/' .. key .. '?fields=' .. fields_csv

  -- See M.search for the cfg-passing rationale. Same contract.
  local cfg, cfg_err = M.config()
  if not cfg then
    on_done(nil, cfg_err)
    return function() end
  end

  return do_request('GET', path, nil, cfg, function(decoded, err)
    if err then
      on_done(nil, err)
      return
    end

    on_done(normalize_issue(decoded, cfg.base_url), nil)
  end)
end

return M
