return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    version = "3.13.3",
    opts = {},
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    lazy = false,
    opts = {},
  },
  { "numToStr/Comment.nvim", lazy = false, keys = {
  {
    "<leader>/",
    function()
      require("Comment.api").toggle.linewise.count(vim.v.count > 0 and vim.v.count or 1)
    end,
    desc = "Toggle linewise comment",
    mode = "n"
  },  {
    "<leader>/",
    "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>",
    desc = "Toggle block comment",
    mode = "v"
  }
  } },
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
