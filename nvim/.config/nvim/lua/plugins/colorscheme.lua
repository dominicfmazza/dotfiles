return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup {
        background = {
          dark = "frappe",
          light = "latte",
        },
        color_overrides = {
          mocha = {
            rosewater = "#ffd7d9",
            flamingo = "#ffb3b8",
            pink = "#ff9cac",
            mauve = "#c792ea",
            red = "#f07178",
            maroon = "#dc6068",
            peach = "#f78c6c",
            yellow = "#ffcb6b",
            green = "#c3e88d",
            teal = "#89ddff",
            sky = "#b0c9ff",
            sapphire = "#82aaff",
            blue = "#6e98eb",
            lavender = "#b480d6",
            text = "#f4f4f4",
            subtext1 = "#e0e0e0",
            subtext0 = "#c6c6c6",
            overlay2 = "#a8a8a8",
            overlay1 = "#8d8d8d",
            overlay0 = "#6f6f6f",
            surface2 = "#474747",
            surface1 = "#3f3f3f",
            surface0 = "#343434",
            base = "#212121",
            mantle = "#1a1a1a",
            crust = "#1a1a1a",
          },
        },
        highlight_overrides = {
          all = function(colors)
            return {
              SnacksIndentScope = { fg = colors.subtext0 },
              SnacksIndentChunk = { fg = colors.subtext0 },
            }
          end,
        },
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          treesitter = true,
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
--  main = {
--         white      = "#EEFFFF",
--         gray       = "#717CB4",
--         black      = "#000000",
--         red        = "#F07178",
--         green      = "#C3E88D",
--         yellow     = "#FFCB6B",
--         blue       = "#82AAFF",
--         paleblue   = "#B0C9FF",
--         cyan       = "#89DDFF",
--         purple     = "#C792EA",
--         orange     = "#F78C6C",
--         -- pink       = "#FF9CAC",
--
--         darkred    = "#DC6068",
--         darkgreen  = "#ABCF76",
--         darkyellow = "#E6B455",
--         darkblue   = "#6E98EB",
--         darkcyan   = "#71C6E7",
--         darkpurple = "#B480D6",
--         darkorange = "#E2795B",
--     },
-- if high_visibility.darker then
--         -- Darker theme style with high contrast
--         colors.editor.line_numbers = "#5C5C5C"
--         colors.syntax.comments     = "#757575"
--     else
--         -- default Darker theme style
--         colors.editor.line_numbers = "#424242"
--         colors.syntax.comments     = "#515151"
--     end
--
--     colors.editor.bg        = "#212121"
--     colors.editor.bg_alt    = "#1A1A1A"
--     colors.editor.fg        = "#B0BEC5"
--     colors.editor.fg_dark   = "#8C8B8B"
--     colors.editor.selection = "#404040"
--     colors.editor.contrast  = "#1A1A1A"
--     colors.editor.active    = "#323232"
--     colors.editor.border    = "#343434"
--     colors.editor.highlight = "#3F3F3F"
--     colors.editor.disabled  = "#474747"
--     colors.editor.accent    = "#FF9800"
