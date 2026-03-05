vim.lsp.config['vtsls'] = {
  -- Command and arguments to start the server.
  cmd = { 'vtsls', '--stdio' },
  filetypes = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
  },
  root_markers = { 'package.json', '.git' },
  settings = {
    vtsls = {
      experimental = {
        completion = {
          enableServerSideFuzzyMatch = true,
          entriesLimit = 50,
        },
      },
    },
  },
}
