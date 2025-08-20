local colortable = require("colors").colortable
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup {
        transparent_background = true,
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
