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

-- Open terminal picker
map("n", "<leader>tl", ":TermSelect<CR>", { noremap = true, silent = true, desc = "Terminal picker" })

-- Send text to last focused terminal
map({ "n", "x" }, "<leader>ts", ":TermSend! new_line=false<CR>", { noremap = true, silent = true, desc = "Send text to last focused terminal" })

-- Send and show output without focusing terminal
map({ "n", "x" }, "<leader>tx", ":TermSend! action=open<CR>", { noremap = true, silent = true, desc = "Send without focusing" })

map({ "x", "n", "t" }, "<M-'>", "<cmd>tabNext<CR>", { noremap = true, silent = true, desc = "" })
map({ "x", "n", "t" }, "<M-;>", "<cmd>tabprevious<CR>", { noremap = true, silent = true, desc = "" })
map({ "x", "n", "t" }, "<M-g>", function()
  local working_directory = vim.fn.getcwd(-1, vim.api.nvim_get_current_tabpage())
  local project_name = "lg-" .. vim.fn.fnamemodify(working_directory, ":t")
  local server = ergoterm.find(function(term) return term.name == project_name end)
  if server then
    server:toggle()
  else
    ergoterm:new {
      layout = "float",
      name = project_name,
      cmd = "lazygit",
      cleanup_on_success = true,
    }
  end
end, { noremap = true, silent = true, desc = "" })

map({ "x", "n", "t" }, "<M-f>", function()
  local working_directory = vim.fn.getcwd(-1, vim.api.nvim_get_current_tabpage())
  local project_name = "shell-" .. vim.fn.fnamemodify(working_directory, ":t")
  local server = ergoterm.find(function(term) return term.name == project_name end)
  if server then
    server:toggle()
  else
    ergoterm:new {
      layout = "float",
      name = project_name,
    }
  end
end, { noremap = true, silent = true, desc = "Open float" })

map({ "x", "n", "t" }, "<M-s>", function()
  local server = ergoterm.find(function(term) return term.name == "scratch" end)
  if server then
    server:toggle()
  else
    ergoterm:new {
      layout = "float",
      name = "scratch",
    }
  end
end, { noremap = true, silent = true, desc = "Open float" })
map("t", "<C-e>", [[<C-\><C-n>]], { noremap = true, silent = true, desc = "" })
