vim.api.nvim_create_autocmd('UIEnter', {
  once = true,
  callback = function()
    vim.schedule(function()
      require('sonarlint').setup {
        server = {
          cmd = {
            'sonarlint-language-server',
            '-stdio',
            '-analyzers',
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarpython.jar',
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarcfamily.jar',
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarjava.jar',
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarjs.jar',
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarhtml.jar',
          },
        },
        filetypes = {
          'cs',
          'css',
          'cpp',
          'dockerfile',
          'html',
          'java',
          'javascript',
          'python',
          'typescript',
        },
      }
    end)
  end,
})
