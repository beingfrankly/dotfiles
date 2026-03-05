-- Nordic theme colors for Sketchybar (Lua version)
-- Require this in your sketchybar config: local colors = require("theme.sketchybar")

local colors = {
  -- Background colors (10% increased contrast)
  bar_bg = 0xff1b1f26,          -- black1 - darker
  bar_bg_dark = 0xff171a20,     -- black0 - darkest
  item_bg = 0xff353b4a,         -- gray2 - darker
  popup_bg = 0xff1b1f26,        -- black1 - darker

  -- Foreground colors (10% increased contrast)
  fg = 0xffdce1eb,              -- white1 - lighter
  fg_bright = 0xffeef1f5,       -- white3 - brighter
  fg_dim = 0xffbbc3d4,          -- white0

  -- Accent colors
  blue = 0xff81a1c1,            -- blue1
  blue_bright = 0xff88c0d0,     -- blue2
  cyan = 0xff8fbcbb,            -- cyan
  green = 0xffa3be8c,           -- green
  yellow = 0xffebcb8b,          -- yellow
  orange = 0xffd08770,          -- orange
  red = 0xffbf616a,             -- red
  magenta = 0xffb48ead,         -- magenta

  -- UI colors (10% increased contrast)
  border = 0xff353b4a,          -- gray2 - darker
  selection = 0xff353b4a,       -- gray2 - darker
  comment = 0xff60728a,         -- gray5

  -- Transparent
  transparent = 0x00000000,

  -- Color with opacity helper
  with_alpha = function(color, alpha)
    return (color & 0x00ffffff) | (alpha << 24)
  end,
}

-- Common defaults for Sketchybar
colors.defaults = {
  bar = {
    color = colors.bar_bg,
    border_color = colors.border,
  },
  icon = {
    color = colors.fg,
  },
  label = {
    color = colors.fg,
  },
  background = {
    color = colors.item_bg,
  },
  popup = {
    background = {
      color = colors.popup_bg,
      border_color = colors.border,
    },
  },
}

-- Item state presets
colors.states = {
  active = {
    icon = { color = colors.fg_bright },
    label = { color = colors.fg_bright },
    background = { color = colors.blue },
  },
  inactive = {
    icon = { color = colors.fg_dim },
    label = { color = colors.fg_dim },
    background = { color = colors.item_bg },
  },
  warning = {
    icon = { color = colors.yellow },
    label = { color = colors.yellow },
  },
  error = {
    icon = { color = colors.red },
    label = { color = colors.red },
  },
  success = {
    icon = { color = colors.green },
    label = { color = colors.green },
  },
}

return colors
