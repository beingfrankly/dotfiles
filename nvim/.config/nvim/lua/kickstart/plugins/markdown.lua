local configured = false

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function()
    if configured then
      return
    end
    configured = true

    -- render-markdown.nvim
    require('render-markdown').setup {
      heading = {
        enabled = true,
        sign = true,
        icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
        backgrounds = {
          'RenderMarkdownH1Bg',
          'RenderMarkdownH2Bg',
          'RenderMarkdownH3Bg',
          'RenderMarkdownH4Bg',
          'RenderMarkdownH5Bg',
          'RenderMarkdownH6Bg',
        },
        foregrounds = {
          'RenderMarkdownH1',
          'RenderMarkdownH2',
          'RenderMarkdownH3',
          'RenderMarkdownH4',
          'RenderMarkdownH5',
          'RenderMarkdownH6',
        },
      },
      code = {
        enabled = true,
        sign = false,
        style = 'full',
        left_pad = 1,
        right_pad = 1,
        width = 'block',
        border = 'thin',
      },
      bullet = {
        enabled = true,
        icons = { '•', '◦', '▪', '▫' },
        right_pad = 1,
      },
      checkbox = {
        enabled = true,
        unchecked = { icon = '󰄱 ' },
        checked = { icon = ' ' },
      },
    }

    -- Rosé Pine highlight groups
    vim.api.nvim_set_hl(0, 'RenderMarkdownH1', { fg = '#eb6f92', bold = true })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH1Bg', { bg = '#2a2837' })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH2', { fg = '#9ccfd8', bold = true })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH2Bg', { bg = '#26283d' })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH3', { fg = '#c4a7e7', bold = true })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH3Bg', { bg = '#2d2a3a' })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH4', { fg = '#f6c177', bold = true })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH5', { fg = '#31748f', bold = true })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH6', { fg = '#908caa', bold = true })

    -- vim-table-mode
    vim.g.table_mode_corner = '|'

    -- Keymaps
    vim.keymap.set('n', '<leader>mp', '<cmd>MarkdownPreviewToggle<cr>', { desc = '[M]arkdown [P]review' })
    vim.keymap.set('n', '<leader>mt', '<cmd>TableModeToggle<cr>', { desc = '[M]arkdown [T]able mode' })
  end,
})
