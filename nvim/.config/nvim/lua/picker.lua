require("fzf-lua").setup { "fzf-tmux" }

vim.keymap.set("n", "<leader>ff", function() require("fzf-lua").files() end, { desc = "Find Files" })
vim.keymap.set("n", "<leader>ft", "<cmd>TodoFzfLua<cr>", { desc = "Find TODOs" })
vim.keymap.set("n", "<leader>fg", function() require("fzf-lua").grep_project { hidden = true } end, { desc = "Live Grep" })
vim.keymap.set("n", "<leader>fb", function() require("fzf-lua").buffers() end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>f/", function() require("fzf-lua").blines() end, { desc = "Current Buffer" })
vim.keymap.set("n", "<leader>fw", function() require("fzf-lua").grep_cword() end, { desc = "Find word under cursor" })
