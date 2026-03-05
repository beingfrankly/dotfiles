-- Enhanced support for Obsidian Bases
-- Syntax highlighting, snippets, and utilities for .base files and base code blocks

return {
  {
    -- YAML frontmatter (properties) support
    'cuducos/yaml.nvim',
    ft = { 'yaml', 'markdown' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-telescope/telescope.nvim',
    },
  },

  {
    -- LuaSnip for Base query snippets
    'L3MON4D3/LuaSnip',
    dependencies = { 'rafamadriz/friendly-snippets' },
    config = function()
      local ls = require 'luasnip'
      local s = ls.snippet
      local t = ls.text_node
      local i = ls.insert_node

      -- Snippets for Obsidian Bases
      ls.add_snippets('markdown', {
        -- Embedded base code block
        s('base', {
          t { '```base', '' },
          t 'source: ',
          i(1, 'folder("path")'),
          t { '', 'filter: ' },
          i(2, 'property = "value"'),
          t { '', 'sort: ' },
          i(3, 'property asc'),
          t { '', 'view: ' },
          i(4, 'table'),
          t { '', '```' },
        }),

        -- Table view
        s('base-table', {
          t { '```base', '' },
          t 'source: ',
          i(1, 'folder(".")'),
          t { '', 'view: table', '' },
          t 'columns: ',
          i(2, 'name, status, date'),
          t { '', '```' },
        }),

        -- Cards view
        s('base-cards', {
          t { '```base', '' },
          t 'source: ',
          i(1, 'folder(".")'),
          t { '', 'view: cards', '' },
          t 'card-layout: ',
          i(2, 'vertical'),
          t { '', '```' },
        }),

        -- List view
        s('base-list', {
          t { '```base', '' },
          t 'source: ',
          i(1, 'folder(".")'),
          t { '', 'view: list', '' },
          t 'group-by: ',
          i(2, 'status'),
          t { '', '```' },
        }),

        -- YAML properties template
        s('props', {
          t { '---', '' },
          t 'title: ',
          i(1, 'Title'),
          t { '', 'status: ' },
          i(2, 'draft'),
          t { '', 'tags: [' },
          i(3, 'tag'),
          t { ']', 'created: ' },
          i(4, '2025-10-11'),
          t { '', '---', '' },
        }),
      })

      -- Enable LuaSnip expansion
      vim.keymap.set({ 'i', 's' }, '<C-k>', function()
        if ls.expand_or_jumpable() then
          ls.expand_or_jump()
        end
      end, { silent = true, desc = 'Expand snippet or jump to next field' })

      vim.keymap.set({ 'i', 's' }, '<C-j>', function()
        if ls.jumpable(-1) then
          ls.jump(-1)
        end
      end, { silent = true, desc = 'Jump to previous snippet field' })
    end,
  },

  {
    -- Enhanced markdown concealing for base blocks
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        'yaml',
        'markdown',
        'markdown_inline',
      })
    end,
  },
}
