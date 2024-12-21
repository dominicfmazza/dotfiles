return {
  "stevearc/quicker.nvim",
  event = "FileType qf",
  ---@module "quicker"
  ---@type quicker.SetupOptions
  opts = {},
  config = function()
    require("which-key").add {
      { "<leader>v", group = "QuickFix" },
      noremap = true,
    }
    require("quicker").setup()
    vim.keymap.set("n", "<leader>vq", function()
      require("quicker").toggle()
    end, {
      desc = "Toggle quickfix",
    })
    vim.keymap.set("n", "<leader>vl", function()
      require("quicker").toggle { loclist = true }
    end, {
      desc = "Toggle loclist",
    })
    require("quicker").setup {
      keys = {
        {
          ">",
          function()
            require("quicker").expand { before = 2, after = 2, add_to_existing = true }
          end,
          desc = "Expand quickfix context",
        },
        {
          "<",
          function()
            require("quicker").collapse()
          end,
          desc = "Collapse quickfix context",
        },
      },
    }
  end,
}
