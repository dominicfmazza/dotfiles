local map = vim.keymap.set

map("i", "jk", "<ESC>")
map("i", "kj", "<ESC>")
map("n", "<Esc>", "<cmd>noh<CR>", { desc = "General Clear highlights" })

require "mappings.comment"

local wk = require "which-key"
wk.add {
  { "<leader>c", "<cmd>close<cr>", desc = "Close" },
  { "<leader>q", "<cmd>q<cr>", desc = "Quit" },
  { "<leader>w", "<cmd>w<cr>", desc = "Save" },
}

wk.add {
  { "J", "5j", desc = "Move to left split" },
  { "K", "5k", desc = "Move to above split" },
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
wk.add {
  { "<leader>bq", "<cmd>silent! w <bar> %bd <bar> e# <bar> bd# <CR>", desc = "Close all buffers but current", silent = true },
}
