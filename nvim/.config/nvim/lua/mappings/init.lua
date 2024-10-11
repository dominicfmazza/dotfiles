local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("n", "<Esc>", "<cmd>noh<CR>", { desc = "General Clear highlights" })

require "mappings.comment"

local wk = require "which-key"
wk.add {
  { "<leader>c", "<cmd>close<cr>", desc = "Close" },
  { "<leader>q", "<cmd>q<cr>", desc = "Quit" },
  { "<leader>w", "<cmd>w<cr>", desc = "Save" },
}

wk.add {
  { "<C-H>", "<C-w>h", desc = "Move to left split" },
  { "<C-J>", "<C-w>j", desc = "Move to below split" },
  { "<C-K>", "<C-w>k", desc = "Move to above split" },
  { "<C-L>", "<C-w>l", desc = "Move to right split" },
}

wk.add {
  { "J", "5j", desc = "Move to left split" },
  { "K", "5k", desc = "Move to above split" },
  noremap = true,
  mode = { "n", "v" },
}

wk.add {
  { "<C-d>", "<C-d>zz" },
  { "<C-d>", "<C-d>zz" },
  noremap = true,
  mode = { "n", "v" },
}

wk.add {
  { "<S-Tab>", "<gv", desc = "Unindent line", mode = "v" },
  { "<Tab>", ">gv", desc = "Indent line", mode = "v" },
}
wk.add {
  { "\\", "<cmd>split<cr>", desc = "Horizontal Split" },
  { "|", "<cmd>vsplit<cr>", desc = "Vertical Split" },
}
