-- Obsidian.nvim - Neovim plugin for Obsidian
-- https://github.com/epwalsh/obsidian.nvim

return {
  'epwalsh/obsidian.nvim',
  version = '*',
  lazy = true,
  ft = 'markdown',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'hrsh7th/nvim-cmp',
    'nvim-telescope/telescope.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {
    workspaces = {
      {
        name = 'second-brain',
        path = '/Users/Frank.vanEldijk/Sync/Obsidian/Second brain',
      },
      -- Add more vaults here if needed
      -- {
      --   name = 'work',
      --   path = '~/Documents/Obsidian/work',
      -- },
    },

    -- Optional: Completion of note references and tags
    completion = {
      nvim_cmp = true,
      min_chars = 2,
    },

    -- Optional: Daily notes configuration
    daily_notes = {
      folder = 'daily',
      date_format = '%Y-%m-%d',
      alias_format = '%B %-d, %Y',
      template = nil,
    },

    -- Optional: Templates
    templates = {
      folder = 'templates',
      date_format = '%Y-%m-%d',
      time_format = '%H:%M',
      substitutions = {},
    },

    -- Optional: Note ID generation
    note_id_func = function(title)
      -- Create note IDs from title if provided
      local suffix = ''
      if title ~= nil then
        suffix = title:gsub(' ', '-'):gsub('[^A-Za-z0-9-]', ''):lower()
      else
        -- If no title, use timestamp
        suffix = tostring(os.time())
      end
      return suffix
    end,

    -- Optional: Specify how to name new notes
    note_frontmatter_func = function(note)
      local out = { id = note.id, aliases = note.aliases, tags = note.tags }
      if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
        for k, v in pairs(note.metadata) do
          out[k] = v
        end
      end
      return out
    end,

    -- Optional: Follow links behavior
    follow_url_func = function(url)
      vim.fn.jobstart({ 'open', url })
    end,

    -- Optional: UI configuration
    ui = {
      enable = true,
      update_debounce = 200,
      checkboxes = {
        [' '] = { char = '󰄱', hl_group = 'ObsidianTodo' },
        ['x'] = { char = '', hl_group = 'ObsidianDone' },
        ['>'] = { char = '', hl_group = 'ObsidianRightArrow' },
        ['~'] = { char = '󰰱', hl_group = 'ObsidianTilde' },
      },
      bullets = { char = '•', hl_group = 'ObsidianBullet' },
      external_link_icon = { char = '', hl_group = 'ObsidianExtLinkIcon' },
      reference_text = { hl_group = 'ObsidianRefText' },
      highlight_text = { hl_group = 'ObsidianHighlightText' },
      tags = { hl_group = 'ObsidianTag' },
      hl_groups = {
        ObsidianTodo = { bold = true, fg = '#eb6f92' }, -- Rosé Pine love
        ObsidianDone = { bold = true, fg = '#9ccfd8' }, -- Rosé Pine foam
        ObsidianRightArrow = { bold = true, fg = '#c4a7e7' }, -- Rosé Pine iris
        ObsidianTilde = { bold = true, fg = '#f6c177' }, -- Rosé Pine gold
        ObsidianBullet = { bold = true, fg = '#31748f' }, -- Rosé Pine pine
        ObsidianRefText = { underline = true, fg = '#c4a7e7' },
        ObsidianExtLinkIcon = { fg = '#31748f' },
        ObsidianTag = { italic = true, fg = '#9ccfd8' },
        ObsidianHighlightText = { bg = '#26233a' },
      },
    },

    -- Optional: Attachments configuration
    attachments = {
      img_folder = 'assets/imgs',
      img_text_func = function(client, path)
        local link_path = client:vault_relative_path(path) or path
        return string.format('![%s](%s)', link_path.name, link_path)
      end,
    },

    -- Optional: YAML frontmatter support for Obsidian Bases
    -- Preserve all YAML properties when editing
    yaml_parser = 'native',
  },

  -- Keybindings
  keys = {
    -- Search/Navigation
    { '<leader>of', '<cmd>ObsidianQuickSwitch<cr>', desc = '[O]bsidian: [F]ind notes' },
    { '<leader>os', '<cmd>ObsidianSearch<cr>', desc = '[O]bsidian: [S]earch in notes' },
    { '<leader>ob', '<cmd>ObsidianBacklinks<cr>', desc = '[O]bsidian: [B]acklinks' },
    { '<leader>ot', '<cmd>ObsidianTags<cr>', desc = '[O]bsidian: [T]ags' },
    { '<leader>ol', '<cmd>ObsidianLinks<cr>', desc = '[O]bsidian: [L]inks' },

    -- Note Creation
    { '<leader>on', '<cmd>ObsidianNew<cr>', desc = '[O]bsidian: [N]ew note' },
    { '<leader>ot', '<cmd>ObsidianTemplate<cr>', desc = '[O]bsidian: Insert [T]emplate' },

    -- Daily Notes
    { '<leader>od', '<cmd>ObsidianToday<cr>', desc = '[O]bsidian: Today' },
    { '<leader>oy', '<cmd>ObsidianYesterday<cr>', desc = '[O]bsidian: Yesterday' },
    { '<leader>om', '<cmd>ObsidianTomorrow<cr>', desc = '[O]bsidian: Tomorrow' },

    -- Current Note
    { '<leader>oo', '<cmd>ObsidianOpen<cr>', desc = '[O]bsidian: [O]pen in app' },
    { 'gf', '<cmd>ObsidianFollowLink<cr>', desc = '[O]bsidian: Follow link', ft = 'markdown' },

    -- Utilities
    { '<leader>oc', '<cmd>ObsidianToggleCheckbox<cr>', desc = '[O]bsidian: Toggle [C]heckbox' },
    { '<leader>op', '<cmd>ObsidianPasteImg<cr>', desc = '[O]bsidian: [P]aste image' },
    { '<leader>or', '<cmd>ObsidianRename<cr>', desc = '[O]bsidian: [R]ename note' },

    -- Workspace
    { '<leader>ow', '<cmd>ObsidianWorkspace<cr>', desc = '[O]bsidian: Switch [W]orkspace' },
  },
}
