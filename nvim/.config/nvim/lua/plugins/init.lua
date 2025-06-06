return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = { preset = "helix" },
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    lazy = false,
    opts = {},
  },
  {
    "nmac427/guess-indent.nvim",
    event = "User FilePost",
    opts = {},
  },
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  { "echasnovski/mini.align", opts = {}, version = false, lazy = false },
  { "yochem/jq-playground.nvim", cmd = { "JqPlayground" } },
  { "echasnovski/mini.ai", version = "*", event = "User FilePost", config = function() require("mini.ai").setup() end },
}
