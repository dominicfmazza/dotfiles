return {{
  "nvim-neo-tree/neo-tree.nvim",
  lazy = false,
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  keys = {
    { "<leader>e", "<cmd>Neotree focus filesystem toggle<cr>", desc = "Filetree: Toggle" },
  },
  config = function()
    require("neo-tree").setup {
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
        },
      },
    }
  end,
},
    {
          'stevearc/oil.nvim',
          ---@module 'oil'
          ---@type oil.SetupOpts
          opts = {
            default_file_explorer =false,
        },
          -- Optional dependencies
          dependencies = { { "echasnovski/mini.icons", opts = {} } },
          -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
          -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
          lazy = false,
    }
}
