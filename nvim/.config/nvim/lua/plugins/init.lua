return {
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    lazy = false,
    opts = {},
  },
  {
    "nmac427/guess-indent.nvim",
    lazy = false,
    opts = {},
  },
  {
    {
      "rachartier/tiny-inline-diagnostic.nvim",
      lazy = false,
      priority = 1000, -- needs to be loaded in first
      config = function()
        vim.diagnostic.config {
          signs = {
            text = {
              [vim.diagnostic.severity.ERROR] = "",
              [vim.diagnostic.severity.WARN] = "",
              [vim.diagnostic.severity.INFO] = "",
              [vim.diagnostic.severity.HINT] = "󰌵",
            },
          },
        }
        require("tiny-inline-diagnostic").setup {
          options = {
            show_source = {
              if_many = true,
            },
            multilines = {
              enabled = true,
              always_show = true,
            },
          },
        }
      end,
    },
  },
  {
    "luukvbaal/statuscol.nvim",
    lazy = false,
    dependencies = { "lewis6991/gitsigns.nvim" },
    config = function() require("statuscol").setup {} end,
  },
}
