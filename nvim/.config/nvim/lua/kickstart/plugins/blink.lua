require('blink.cmp').setup {
  keymap = { preset = 'super-tab' },

  appearance = {
    nerd_font_variant = 'mono',
  },

  completion = {
    documentation = {
      auto_show = false,
    },
    ghost_text = { enabled = true },
  },

  signature = { enabled = true },

  cmdline = { enabled = true },

  sources = {
    default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
    providers = {
      lazydev = {
        name = 'LazyDev',
        module = 'lazydev.integrations.blink',
        score_offset = 100,
      },
    },
  },

  fuzzy = { implementation = 'prefer_rust_with_warning' },
}
