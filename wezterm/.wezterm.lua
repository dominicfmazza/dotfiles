-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28

-- or, changing the font size and color scheme.
config.font_size = 12
config.color_scheme = 'Material Darker (base16)'

config.font = wezterm.font({
  family = "MonaspiceAr Nerd Font",
  assume_emoji_presentation = true,
})


-- Finally, return the configuration to wezterm:
return config
