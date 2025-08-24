return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    priority = 900,
    config = function()
      -- calling `setup` is optional for customization
      require("fzf-lua").setup { "fzf-tmux" }
    end,
    keys = {
      {
        "<leader>ff",
        function() require("fzf-lua").files() end,
        desc = "Find Files",
      },
      { "<leader>ft", "<cmd>TodoFzfLua<cr>", desc = "Find TODOs" },
      {
        "<leader>fg",
        function() require("fzf-lua").grep_project { hidden = true } end,
        desc = "Live Grep",
      },
      {
        "<leader>fb",
        function() require("fzf-lua").buffers() end,
        desc = "Buffers",
      },
      {
        "<leader>f/",
        function() require("fzf-lua").blines() end,
        desc = "Current Buffer",
      },
      {
        "<leader>fw",
        function() require("fzf-lua").grep_cword() end,
        desc = "Find word under cursor",
      },
    },
  },
}
