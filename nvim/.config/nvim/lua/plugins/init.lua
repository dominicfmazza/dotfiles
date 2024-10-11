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
    opts = {},
    lazy = false,
  },
  {
    "hiphish/rainbow-delimiters.nvim",
    lazy = false,
  },
}
