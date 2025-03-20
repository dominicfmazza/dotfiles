return {
  {
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
      { "<leader>o", "<cmd>Neotree focus filesystem<cr>", desc = "Filetree: Focus" },
    },
  },
}

