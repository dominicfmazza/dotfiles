local miniclue = require "mini.clue"
miniclue.setup {
  triggers = {
    -- Leader triggers
    { mode = "n", keys = "<Leader>" },
    { mode = "x", keys = "<Leader>" },

    -- Built-in completion
    { mode = "i", keys = "<C-x>" },

    -- `g` key
    { mode = "n", keys = "g" },
    { mode = "x", keys = "g" },

    -- Marks
    { mode = "n", keys = "'" },
    { mode = "n", keys = "`" },
    { mode = "x", keys = "'" },
    { mode = "x", keys = "`" },

    -- Registers
    { mode = "n", keys = '"' },
    { mode = "x", keys = '"' },
    { mode = "i", keys = "<C-r>" },
    { mode = "c", keys = "<C-r>" },

    -- Window commands
    { mode = "n", keys = "<C-w>" },

    -- `z` key
    { mode = "n", keys = "z" },
    { mode = "x", keys = "z" },
  },

  clues = {
    -- Enhance this by adding descriptions for <Leader> mapping groups
    miniclue.gen_clues.builtin_completion(),
    miniclue.gen_clues.g(),
    miniclue.gen_clues.marks(),
    miniclue.gen_clues.registers(),
    miniclue.gen_clues.windows(),
    miniclue.gen_clues.z(),
    { mode = "n", keys = "<Leader>l", desc = "+LSP" },
    { mode = "n", keys = "<Leader>o", desc = "+Obsidian" },
    { mode = "n", keys = "<Leader>f", desc = "+Picker" },
    { mode = "n", keys = "<Leader>g", desc = "+Git" },
    { mode = "n", keys = "<Leader>v", desc = "+Lists" },
    { mode = "n", keys = "<Leader>t", desc = "+Terminal" },
  },
}
local map = vim.keymap.set
map({ "i", "n", "x", "t" }, "<M-h>", "<C-w>h")
map({ "i", "n", "x", "t" }, "<M-j>", "<C-w>j")
map({ "i", "n", "x", "t" }, "<M-k>", "<C-w>k")
map({ "i", "n", "x", "t" }, "<M-l>", "<C-w>l")

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "General Clear highlights" })
map("n", "<C-[>", "<cmd>noh<CR>", { desc = "General Clear highlights" })

map("n", "<leader>c", "<cmd>close<cr>", { desc = "Close buffer" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Write" })
map("n", "<Leader>/", "gcc", { remap = true })
map("x", "<Leader>/", "gc", { remap = true })

map({ "n", "x" }, "J", "", { noremap = true })
map({ "n", "x" }, "K", "")

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

map("n", "<leader>e", "<cmd>Neotree focus filesystem toggle<cr>", { noremap = true })

map("n", "<leader>vv", function() require("quicker").toggle() end, {
  desc = "Toggle quickfix",
})
map("n", "<leader>vl", function() require("quicker").toggle { loclist = true } end, {
  desc = "Toggle loclist",
})
map("n", "<leader>vn", "<cmd>cnext<cr>", { noremap = true })
map("n", "<leader>vp", "<cmd>cprevious<cr>", { noremap = true })
