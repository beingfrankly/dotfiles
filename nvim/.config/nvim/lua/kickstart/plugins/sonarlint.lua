return {
  {
    'https://gitlab.com/schrieveslaach/sonarlint.nvim',
    lazy = true,
    event = 'VeryLazy',
    config = function()
      local sonarlint = require 'sonarlint'
      sonarlint.setup {
        server = {
          cmd = {
            'sonarlint-language-server',
            -- Ensure that sonarlint-language-server uses stdio channel
            '-stdio',
            '-analyzers',
            -- paths to the analyzers you need, using those for python and java in this example
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarpython.jar',
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarcfamily.jar',
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarjava.jar',
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarjs.jar',
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarhtml.jar',
          },
          -- settings = {
            -- sonarlint = {
            --   connectedMode = {
            --     connections = {
            --       sonarcloud = {
            --         {
            --           connectionId = 'hfs-sonarcloud',
            --           region = 'EU',
            --           organizationKey = 'hfg',
            --           disableNotifications = false,
            --         },
            --       },
            --     },
            --     project = {},
            --   },
            -- },
          -- },
        },
        -- connected = {
        --   get_credentials = function()
        --     return os.getenv 'SONARLINT_NVIM'
        --   end,
        -- },
        -- before_init = function(params)
        --   local root = params.rootPath or params.rootUri
        --   if root and root:find '/Users/Frank.vanEldijk/code/hfs/striive%-portals' then
        --     params.initializationOptions = params.initializationOptions or {}
        --     params.initializationOptions.connectedMode = {
        --       project = {
        --         connectionId = 'hfs-sonarcloud',
        --         projectKey = 'hfs-striive-portals',
        --       },
        --     }
        --   end
        -- end,
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
    end,
  },
}
