local colortable = require("colors").colortable
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup {
        transparent_background = true,
        custom_highlights = function(colors)
          local u = require "catppuccin.utils.colors"
          return {
            CursorLineNr = { bg = u.blend(colors.overlay0, colors.base, 0.75), style = { "bold" } },
            CursorLine = { bg = u.blend(colors.overlay0, colors.base, 0.75) },
            LspReferenceText = { bg = colors.surface2 },
            LspReferenceWrite = { bg = colors.surface2 },
            LspReferenceRead = { bg = colors.surface2 },
          }
        end,
        color_overrides = {
          mocha = colortable,
        },
        integrations = {
          blink_cmp = true,
          gitsigns = true,
          nvimtree = true,
          treesitter = true,
          which_key = true,
          fidget = true,
          fzf = true,
          mini = {
            enabled = true,
            indentscope_color = "",
          },
        },
      }
    end,
  },
}
