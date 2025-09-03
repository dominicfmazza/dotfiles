local colortable = require("colors").colortable
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup {
        color_overrides = {
          mocha = colortable,
        },
        integrations = {
          blink_cmp = true,
          gitsigns = true,
          neotree = false,
          fidget = true,
          fzf = true,
          mini = {
            enabled = false,
            indentscope_color = "",
          },
        },
      }
    end,
  },
}
