local wezterm = require("wezterm")

local colors = require("lua/rose-pine-moon").colors()
local window_frame = require("lua/rose-pine-moon").window_frame()

local config = {}

config.enable_tab_bar = false
config.colors = colors
config.window_frame = window_frame
config.font_size = 13
config.line_height = 1.4
config.window_padding = {
	left = 0,
	right = 0,
	top = 4,
	bottom = 0,
}
config.window_decorations = "RESIZE"
config.window_frame = {
	font_size = 0,
}
-- config.use_fancy_tab_bar = false
-- config.show_tabs_in_tab_bar = false
-- config.show_new_tab_button_in_tab_bar = false

return config
