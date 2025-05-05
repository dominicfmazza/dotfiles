local map = vim.keymap.set

map("i", "jk", "<ESC>")
map("i", "kj", "<ESC>")
map("n", "<Esc>", "<cmd>noh<CR>", { desc = "General Clear highlights" })
map("n", "<C-[>", "<cmd>noh<CR>", { desc = "General Clear highlights" })

local wk = require "which-key"
wk.add {
  { "<leader>c", "<cmd>close<cr>", desc = "Close" },
  { "<leader>q", "<cmd>q<cr>", desc = "Quit" },
  { "<leader>w", "<cmd>w<cr>", desc = "Save" },
}
wk.add {
  { "<Leader>/", "gcc", remap = true, desc = "Toggle comment line", mode = { "n" } },
  { "<Leader>/", "gc", remap = true, desc = "Toggle comment", mode = { "x" } },
}

wk.add {
  { "J", "5gj", desc = "5Down" },
  { "K", "5gk", desc = "5Up" },
  noremap = true,
  mode = { "n", "v" },
}

wk.add {
  { "<C-J>", "<cmd>join<cr>", desc = "5Down" },
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

vim.keymap.set({ "n", "v" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, noremap = true })
vim.keymap.set({ "n", "v" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, noremap = true })

vim.keymap.set({ "n", "v" }, "gk", "v:count == 0 ? 'k' : 'gk'", { expr = true, noremap = true })
vim.keymap.set({ "n", "v" }, "gj", "v:count == 0 ? 'j' : 'gj'", { expr = true, noremap = true })
