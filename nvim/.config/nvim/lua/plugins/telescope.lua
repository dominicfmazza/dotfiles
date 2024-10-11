return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" },
      {
        "<leader>fg",
        "<cmd>Telescope live_grep<cr>",
        desc = "Live Grep",
      },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
      {
        "<leader>f/",
        "<cmd>Telescope current_buffer_fuzzy_find<cr>",
        desc = "Current Buffer",
      },
      {
        "<leader>fw",
        "<cmd>Telescope grep_string<cr>",
        desc = "Find word under cursor",
      },
    },
    config = function()
      require("telescope").setup()
      -- Telescope Settings
      local wk = require "which-key"

      wk.add {
        { "<leader>f", group = "Telescope" },
        noremap = true,
      }
    end,
  },
}
