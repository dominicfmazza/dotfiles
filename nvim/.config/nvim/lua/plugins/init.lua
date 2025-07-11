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
    opts = {},
  },
  { "yochem/jq-playground.nvim", cmd = { "JqPlayground" } },
}
