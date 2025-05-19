-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28

-- or, changing the font size and color scheme.
config.font_size = 13
config.color_scheme = 'Material Darker (base16)'

config.font = wezterm.font({
  family = "MonaspiceAr Nerd Font",
  assume_emoji_presentation = true,
})

config.window_decorations = 'RESIZE'
config.window_frame = {
  font = wezterm.font({ family = 'MonaspiceAr Nerd Font', weight = 'Bold' }),
  font_size = 13,
}

wezterm.on('update-status', function(window)
  local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

  local color_scheme = window:effective_config().resolved_palette
  local bg = color_scheme.background
  local fg = color_scheme.foreground

  window:set_right_status(wezterm.format({
    { Background = { Color = 'none' } },
    { Foreground = { Color = bg } },
    { Text = SOLID_LEFT_ARROW },
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Text = ' ' .. wezterm.hostname() .. ' ' },
  }))
end)

-- Finally, return the configuration to wezterm:
return config
