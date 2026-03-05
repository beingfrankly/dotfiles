local inlay_hint_settings = {
  parameterNames = { enabled = 'literals' },
  parameterTypes = { enabled = true },
  functionLikeReturnTypes = { enabled = true },
  propertyDeclarationTypes = { enabled = true },
  enumMemberValues = { enabled = true },
  variableTypes = { enabled = false },
}

return {
  cmd = { 'tsgo', '--lsp', '--stdio' },
  filetypes = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
  },
  root_dir = function(bufnr, on_dir)
    local root_markers = { 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml', 'bun.lockb', 'bun.lock' }
    root_markers = vim.fn.has 'nvim-0.11.3' == 1 and { root_markers, { '.git' } } or vim.list_extend(root_markers, { '.git' })

    -- Exclude Deno projects: compare root depths to handle nested Deno modules within Node monorepos
    local node_root = vim.fs.root(bufnr, { 'package.json', 'tsconfig.json', 'jsconfig.json' })
    local deno_root = vim.fs.root(bufnr, { 'deno.json', 'deno.jsonc', 'deno.lock' })
    if deno_root then
      if not node_root or #deno_root >= #node_root then
        return
      end
    end

    local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()
    on_dir(project_root)
  end,
  on_new_config = function(new_config, new_root_dir)
    local local_bin = vim.fs.joinpath(new_root_dir, 'node_modules', '.bin', 'tsgo')
    if vim.uv.fs_stat(local_bin) then
      new_config.cmd = { local_bin, '--lsp', '--stdio' }
    end
  end,
  settings = {
    typescript = {
      inlayHints = inlay_hint_settings,
    },
    javascript = {
      inlayHints = inlay_hint_settings,
    },
  },
}
