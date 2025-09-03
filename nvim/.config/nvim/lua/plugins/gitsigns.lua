return {
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup {
        signcolumn = true,
        signs = {
          delete = { text = "󰍵" },
          changedelete = { text = "󱕖" },
        },
      }
    end,
    keys = {
      { "<leader>g", group = "git" },
      {
        "<leader>gL",
        function() require("gitsigns").blame_line { full = true } end,
        desc = "Full Blame",
        buffer = true,
      },
      {
        "<leader>gS",
        function() require("gitsigns").stage_buffer() end,
        desc = "Stage Buffer",
        buffer = true,
      },
      {
        "<leader>gd",
        function() require("gitsigns").diffthis() end,
        desc = "View Diff",
        buffer = true,
      },
      {
        "<leader>gh",
        function() require("gitsigns").reset_hunk() end,
        desc = "Reset Hunk",
        buffer = true,
      },
      {
        "<leader>gl",
        function() require("gitsigns").blame_line() end,
        desc = "Blame",
        buffer = true,
      },
      {
        "<leader>gp",
        function() require("gitsigns").preview_hunk() end,
        desc = "Preview Hunk",
        buffer = true,
      },
      {
        "<leader>gr",
        function() require("gitsigns").reset_buffer() end,
        desc = "Reset Buffer",
        buffer = true,
      },
      {
        "<leader>gs",
        function() require("gitsigns").stage_hunk() end,
        desc = "Stage Hunk",
        buffer = true,
      },
      {
        "<leader>gu",
        function() require("gitsigns").undo_stage_hunk() end,
        desc = "Unstage Hunk",
        buffer = true,
      },
      {
        "]g",
        function() require("gitsigns").next_hunk() end,
        desc = "Next Hunk",
        buffer = true,
      },
      {
        "[g",
        function() require("gitsigns").prev_hunk() end,
        desc = "Previous Hunk",
        buffer = true,
      },
    },
  },
}
