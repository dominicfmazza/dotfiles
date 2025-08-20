local map = vim.keymap.set

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "General Clear highlights" })
map("n", "<C-[>", "<cmd>noh<CR>", { desc = "General Clear highlights" })

map("n", "<leader>c", "<cmd>close<cr>")
map("n", "<leader>q", "<cmd>q<cr>")
map("n", "<leader>w", "<cmd>w<cr>")
map("n", "<Leader>/", "gcc", { remap = true })
map("x", "<Leader>/", "gc", { remap = true })

map({ "n", "x" }, "J", "5gj", { noremap = true })
map({ "n", "x" }, "K", "5gk")

map({ "n", "v" }, "<C-J>", "<cmd>join<cr>", { noremap = true })

map("v", "<S-Tab>", "<gv")
map("v", "<Tab>", ">gv")

map("n", "\\", "<cmd>split<cr>")
map("n", "|", "<cmd>vsplit<cr>")
map("n", "<leader>bq", "<cmd>silent! w <bar> %bd <bar> e# <bar> bd# <CR>", { silent = true })

map({ "n", "v" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, noremap = true })
map({ "n", "v" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, noremap = true })
map({ "n", "v" }, "gk", "v:count == 0 ? 'k' : 'gk'", { expr = true, noremap = true })
map({ "n", "v" }, "gj", "v:count == 0 ? 'j' : 'gj'", { expr = true, noremap = true })
