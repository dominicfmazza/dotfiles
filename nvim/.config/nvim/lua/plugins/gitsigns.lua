return {
  {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    config = function()
      require("gitsigns").setup {
        signcolumn = true,
        signs = {
          delete = { text = "󰍵" },
          changedelete = { text = "󱕖" },
        },
        on_attach = function(bufnr)
          local wk = require "which-key"
          -- git keybinds
          wk.add {
            { "<leader>g", group = "git" },
            {
              "<leader>gL",
              function() require("gitsigns").blame_line { full = true } end,
              desc = "Full Blame",
              buffer = bufnr,
            },
            {
              "<leader>gS",
              function() require("gitsigns").stage_buffer() end,
              desc = "Stage Buffer",
              buffer = bufnr,
            },
            {
              "<leader>gd",
              function() require("gitsigns").diffthis() end,
              desc = "View Diff",
              buffer = bufnr,
            },
            {
              "<leader>gh",
              function() require("gitsigns").reset_hunk() end,
              desc = "Reset Hunk",
              buffer = bufnr,
            },
            {
              "<leader>gl",
              function() require("gitsigns").blame_line() end,
              desc = "Blame",
              buffer = bufnr,
            },
            {
              "<leader>gp",
              function() require("gitsigns").preview_hunk() end,
              desc = "Preview Hunk",
              buffer = bufnr,
            },
            {
              "<leader>gr",
              function() require("gitsigns").reset_buffer() end,
              desc = "Reset Buffer",
              buffer = bufnr,
            },
            {
              "<leader>gs",
              function() require("gitsigns").stage_hunk() end,
              desc = "Stage Hunk",
              buffer = bufnr,
            },
            {
              "<leader>gu",
              function() require("gitsigns").undo_stage_hunk() end,
              desc = "Unstage Hunk",
              buffer = bufnr,
            },
          }

          wk.add {
            {
              "]g",
              function() require("gitsigns").next_hunk() end,
              desc = "Next Hunk",
              buffer = bufnr,
            },
            {
              "[g",
              function() require("gitsigns").prev_hunk() end,
              desc = "Previous Hunk",
              buffer = bufnr,
            },
          }
        end,
      }
    end,
  },
}
