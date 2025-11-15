require("fzf-lua").setup {
  { "border-fused" },
  actions = {
    files = {
      ["enter"] = FzfLua.actions.file_edit_or_qf,
      ["ctrl-s"] = FzfLua.actions.file_split,
      ["ctrl-v"] = FzfLua.actions.file_vsplit,
      ["ctrl-t"] = FzfLua.actions.file_tabedit,
      ["alt-i"] = FzfLua.actions.toggle_ignore,
      ["alt-h"] = FzfLua.actions.toggle_hidden,
      ["alt-f"] = FzfLua.actions.toggle_follow,
      ["ctrl-q"] = FzfLua.actions.file_sel_to_qf,
      ["ctrl-Q"] = FzfLua.actions.file_sel_to_ll,
    },
  },
}

vim.keymap.set("n", "<leader>ff", function() require("fzf-lua").global() end, { desc = "Find Global" })
vim.keymap.set("n", "<leader>ft", "<cmd>TodoFzfLua<cr>", { desc = "Find TODOs" })
vim.keymap.set("n", "<leader>fg", function() require("fzf-lua").grep_project { hidden = true } end, { desc = "Live Grep" })
vim.keymap.set("n", "<C-b>", function() require("fzf-lua").buffers() end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>f/", function() require("fzf-lua").blines() end, { desc = "Current Buffer" })
vim.keymap.set("n", "<leader>fw", function() require("fzf-lua").grep_cword() end, { desc = "Find word under cursor" })
