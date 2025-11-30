local map = vim.keymap.set
require("gitsigns").setup {
  signcolumn = true,
  signs = {
    delete = { text = "󰍵" },
    changedelete = { text = "󱕖" },
  },
}

map("n", "<leader>gS", function() require("gitsigns").stage_buffer() end, { desc = "Stage Buffer", noremap = true })
map("n", "<leader>gd", function() require("gitsigns").diffthis() end, { desc = "Diff This", noremap = true })
map("n", "<leader>gh", function() require("gitsigns").reset_hunk() end, { desc = "Reset Hunk", noremap = true })
map("n", "<leader>gl", function() require("gitsigns").blame_line() end, { desc = "Blame Line", noremap = true })
map("n", "<leader>gp", function() require("gitsigns").preview_hunk() end, { desc = "Preview Hunk", noremap = true })
map("n", "<leader>gr", function() require("gitsigns").reset_buffer() end, { desc = "Reset Buffer", noremap = true })
map("n", "<leader>gs", function() require("gitsigns").stage_hunk() end, { desc = "Stage Hunk", noremap = true })
map("n", "<leader>gu", function() require("gitsigns").undo_stage_hunk() end, { desc = "Undo Stage Hunk", noremap = true })
map("n", "]g", function() require("gitsigns").next_hunk() end, { desc = "Next Git Hunk", noremap = true })
map("n", "[g", function() require("gitsigns").prev_hunk() end, { desc = "Previous Git Hunk", noremap = true })
