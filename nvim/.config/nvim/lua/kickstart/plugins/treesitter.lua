local ts = require('nvim-treesitter')

local languages = {
  'angular',
  'bash',
  'c',
  'css',
  'diff',
  'git_config',
  'gitcommit',
  'html',
  'java',
  'javascript',
  'json',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'query',
  'regex',
  'scss',
  'toml',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
  'xml',
  'yaml',
}

local function start_highlight(buf, filetype)
  if not vim.api.nvim_buf_is_loaded(buf) then
    return
  end

  local lang = vim.treesitter.language.get_lang(filetype)
  if not lang or not vim.treesitter.language.add(lang) then
    return
  end

  vim.treesitter.start(buf, lang)
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('kickstart-treesitter', { clear = true }),
  callback = function(ev)
    start_highlight(ev.buf, ev.match)
  end,
})

local warm_languages = {
  'typescript',
  'angular',
  'html',
  'java',
  'json',
  'scss',
  'yaml',
  'lua',
  'markdown',
}

local query_kinds = { 'highlights', 'injections', 'folds', 'indents' }

local warm_steps = {}
for _, lang in ipairs(warm_languages) do
  for _, kind in ipairs(query_kinds) do
    warm_steps[#warm_steps + 1] = { lang, kind }
  end
end

local function warm_queries(index)
  local step = warm_steps[index]
  if not step then
    return
  end

  if vim.treesitter.language.add(step[1]) then
    pcall(vim.treesitter.query.get, step[1], step[2])
  end

  vim.schedule(function()
    warm_queries(index + 1)
  end)
end

vim.api.nvim_create_autocmd('UIEnter', {
  once = true,
  callback = function()
    vim.schedule(function()
      ts.install(languages):await(vim.schedule_wrap(function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          start_highlight(buf, vim.bo[buf].filetype)
        end
        warm_queries(1)
      end))
    end)
  end,
})
