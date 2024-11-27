return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    lazy = false,
    opts = {},
  },
  { "numToStr/Comment.nvim" },
  {
    "nmac427/guess-indent.nvim",
    event = "User FilePost",
    opts = {},
  },
  {
    "hiphish/rainbow-delimiters.nvim",
    event = "User FilePost",
  },
}
