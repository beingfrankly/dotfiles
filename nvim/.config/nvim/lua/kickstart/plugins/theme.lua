require('teide').setup {
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
}
vim.cmd.colorscheme 'teide'
