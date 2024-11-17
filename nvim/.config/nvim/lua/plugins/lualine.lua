return {
  {
    "nvim-lualine/lualine.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        component_separators = { left = "|", right = "|" },
        section_separators = { left = "", right = "" },
        always_divide_middle = false,
        globalstatus = true,
        theme = "catppuccin",
      },
      extensions = {
        "neo-tree",
        "toggleterm",
      },
    },
  },
}
