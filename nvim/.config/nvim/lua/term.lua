require("ergoterm").setup {
  terminal_defaults = {
    layout = "right",
    cleanup_on_success = false,
    auto_scroll = true,
  },
  picker = {
    picker = "fzf-lua",
    extra_select_actions = {
      ["<C-d>"] = { fn = function(term) term:cleanup() end, desc = "Delete terminal" },
    },
  },
}

local map = vim.keymap.set
local ergoterm = require "ergoterm"

-- Terminal creation with different layouts
map("n", "<leader>ts", ":TermNew layout=below<CR>", { noremap = true, silent = true, desc = "Open below" })
map("n", "<leader>tv", ":TermNew layout=right<CR>", { noremap = true, silent = true, desc = "Open right" })
map("n", "<leader>tt", ":TermNew layout=tab<CR>", { noremap = true, silent = true, desc = "Open tab" })

-- Open terminal picker
map("n", "<leader>tl", ":TermSelect<CR>", { noremap = true, silent = true, desc = "Terminal picker" })

-- Send text to last focused terminal
map({ "n", "x" }, "<leader>ts", ":TermSend! new_line=false<CR>", { noremap = true, silent = true, desc = "Send text to last focused terminal" })

-- Send and show output without focusing terminal
map({ "n", "x" }, "<leader>tx", ":TermSend! action=open<CR>", { noremap = true, silent = true, desc = "Send without focusing" })

map({ "x", "n", "t" }, "<M-'>", "<cmd>tabNext<CR>", { noremap = true, silent = true, desc = "" })
map({ "x", "n", "t" }, "<M-;>", "<cmd>tabprevious<CR>", { noremap = true, silent = true, desc = "" })
map({ "x", "n", "t" }, "<M-g>", function()
  local server = ergoterm.find(function(term) return term.name == "lazygit" end)
  if server then
    server:toggle()
  else
    ergoterm:new {
      layout = "float",
      name = "lazygit",
      cmd = "lazygit",
      cleanup_on_success = true,
    }
  end
end, { noremap = true, silent = true, desc = "" })
map({ "x", "n", "t" }, "<M-f>", function()
  local server = ergoterm.find(function(term) return term.name == "floating" end)
  if server then
    server:toggle()
  else
    ergoterm:new {
      layout = "float",
      name = "floating",
    }
  end
end, { noremap = true, silent = true, desc = "Open float" })

map("t", "<C-e>", [[<C-\><C-n>]], { noremap = true, silent = true, desc = "" })
