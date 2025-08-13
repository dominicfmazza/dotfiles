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
    lazy = false,
    opts = {},
  },
  { "yochem/jq-playground.nvim", cmd = { "JqPlayground" } },
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
            }
          },
        }
      end,
    },
  },
  {
    "luukvbaal/statuscol.nvim",
    lazy = false,
    dependencies = { "lewis6991/gitsigns.nvim" },
    config = function()
      -- local builtin = require("statuscol.builtin")
      require("statuscol").setup {
        -- configuration goes here, for example:
        -- relculright = true,
        -- segments = {
        --   { text = { builtin.foldfunc }, click = "v:lua.ScFa" },
        --   {
        --     sign = { namespace = { "diagnostic/signs" }, maxwidth = 2, auto = true },
        --     click = "v:lua.ScSa"
        --   },
        --   { text = { builtin.lnumfunc }, click = "v:lua.ScLa", },
        --   {
        --     sign = { name = { ".*" }, maxwidth = 2, colwidth = 1, auto = true, wrap = true },
        --     click = "v:lua.ScSa"
        --   },
        -- }
      }
    end,
  },
}
