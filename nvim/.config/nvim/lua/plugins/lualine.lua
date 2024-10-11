return {
  {
    "nvim-lualine/lualine.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      theme = "catppuccin",
      extensions = {
        "neo-tree",
        "toggleterm"
      },
    },
  },
}
