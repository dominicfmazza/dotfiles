-- return { {
--     "catppuccin/nvim",
--     name = "catppuccin",
--     priority = 1000,
--     opts = {
--       integrations = {
--         cmp = true,
--         gitsigns = true,
--         nvimtree = true,
--         treesitter = true,
--         mini = {
--           enabled = true,
--           indentscope_color = "",
--         },
--       },
--     },
--   },
-- }

-- return {
--   {
--     "navarasu/onedark.nvim",
--     priority = 1000,
--     config = function()
--       require("onedark").setup {
--         style = "darker",
--       }
--       require("onedark").load()
--     end,
--   },
-- }

return {
  {
    "marko-cerovac/material.nvim",
    priority = 1000,
    opts = {
      contrast = {
        sidebars = true,
        cursorline = true,
        lsp_virtual_text = true,
      },
      plugins = {
        "eyeliner",
        "fidget",
        "gitsigns",
        "nvim-cmp",
        "nvim-tree",
        "nvim-web-devicons",
        "rainbow-delimiters",
        "telescope",
        "trouble",
        "which-key",
      },
    },
  },
}
