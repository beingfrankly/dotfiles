return {
  {
    'serhez/teide.nvim',
    lazy = false,
    priority = 1000,
    opts = {
      style = 'darker',
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        functions = {},
        variables = {},
      },
      dim_inactive = false,
      on_colors = function(colors)
        -- Darken backgrounds by 25%
        colors.bg = '#111418'
        colors.bg_dark = '#0e1114'
        colors.bg_highlight = '#232835'
        colors.bg_visual = '#232835'
      end,
    },
    config = function(_, opts)
      require('teide').setup(opts)
      vim.cmd.colorscheme 'teide'
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
