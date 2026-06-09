require('nvim-treesitter').setup {
  ensure_installed = {
    'bash', 'c', 'diff', 'html', 'java', 'lua', 'luadoc',
    'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc',
    'angular', 'typescript', 'tsx',
  },
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = { 'ruby' },
  },
  indent = { enable = true, disable = { 'ruby' } },
}
