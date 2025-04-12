return {
  {
    lazy = false,
    "stevearc/overseer.nvim",
    opts = {},
    config = function()
      require("overseer").setup {
        strategy = "jobstart",
      }
      require("overseer").load_template "cmake"
      require("which-key").add {
        { "<leader>o", group = "+Overseer" },
        { "<leader>oo", "<cmd>OverseerToggle<cr>", desc = "Toggle" },
        { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Run" },
        { "<leader>oc", "<cmd>OverseerClearCache<cr>", desc = "Clear Cache" },
      }
    end,
  },
}
