-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28

-- or, changing the font size and color scheme.
config.font_size = 14
-- config.color_scheme = "Material Darker (base16)"
config.colors = {
	background = "#0f0f0f",
	foreground = "#cdcdcd",

	cursor_bg = "#cdcdcd",
	cursor_fg = "#141415",
	cursor_border = "#cdcdcd",

	selection_fg = "#cdcdcd",
	selection_bg = "#252530",

	scrollbar_thumb = "#252530",
	split = "#252530",

	ansi = {
		"#252530",
		"#d8647e",
		"#7fa563",
		"#f3be7c",
		"#6e94b2",
		"#bb9dbd",
		"#aeaed1",
		"#cdcdcd",
	},
	brights = {
		"#606079",
		"#e08398",
		"#99b782",
		"#f5cb96",
		"#8ba9c1",
		"#c9b1ca",
		"#bebeda",
		"#d7d7d7",
	},
	tab_bar = {
		background = "#141415",
		active_tab = {
			bg_color = "#252530",
			fg_color = "#cdcdcd",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
		inactive_tab = {
			bg_color = "#141415",
			fg_color = "#606079",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
		inactive_tab_hover = {
			bg_color = "#252530",
			fg_color = "#cdcdcd",
			italic = false,
		},
		new_tab = {
			bg_color = "#141415",
			fg_color = "#6e94b2",
		},
		new_tab_hover = {
			bg_color = "#252530",
			fg_color = "#8ba9c1",
		},
		inactive_tab_edge = "#252530",
	},
}

config.font = wezterm.font({
	family = "MonaspiceNe Nerd Font",
	weight = "Medium",
	harfbuzz_features = { "calt" },
})

config.window_decorations = "RESIZE"
config.window_frame = {
	font = wezterm.font({ family = "MonaspiceAr Nerd Font", weight = "Bold" }),
	font_size = 13,
}

local status, hosts = pcall(require, "hosts")

if status then
	hosts.configure_hosts(config)
end

wezterm.on("update-status", function(window)
	local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

	local color_scheme = window:effective_config().resolved_palette
	local bg = color_scheme.background
	local fg = color_scheme.foreground

	window:set_right_status(wezterm.format({
		{ Background = { Color = "none" } },
		{ Foreground = { Color = bg } },
		{ Text = SOLID_LEFT_ARROW },
		{ Background = { Color = bg } },
		{ Foreground = { Color = fg } },
		{ Text = " " .. wezterm.hostname() .. " " },
	}))
end)

return config
