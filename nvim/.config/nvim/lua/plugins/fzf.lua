
return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    config = function()
      -- calling `setup` is optional for customization
      require("fzf-lua").setup {"telescope"}

      local wk = require "which-key"
      wk.add {
        { "<leader>f", group = "Telescope" },
        noremap = true,
      }
    end,
    keys = {
      {
        "<leader>ff",
        function()
          require("fzf-lua").files()
        end,
        desc = "Find Files",
      },
      { "<leader>ft", "<cmd>TodoFzfLua<cr>", desc = "Find TODOs" },
      {
        "<leader>fg",
        function()
          require("fzf-lua").grep_project()
        end,
        desc = "Live Grep",
      },
      {
        "<leader>fb",
        function()
          require("fzf-lua").buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>f/",
        function()
          require("fzf-lua").blines()
        end,
        desc = "Current Buffer",
      },
      {
        "<leader>fw",
        function()
          require("fzf-lua").grep_cword()
        end,
        desc = "Find word under cursor",
      },
    },
  },
}
