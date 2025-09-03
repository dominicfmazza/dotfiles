vim.g.mapleader = " "
vim.g.have_nerd_font = true

local opt = vim.opt

-- global options --
opt.incsearch = true -- Find the next match as we type the search
opt.hlsearch = true -- Hilight searches by default
opt.viminfo = "'100,f1" -- Save up to 100 marks, enable capital marks
opt.ignorecase = true -- Ignore case when searching...
opt.smartcase = true -- ...unless we type a capital
opt.autoindent = true
opt.smartindent = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.termguicolors = true
opt.cursorline = true
opt.relativenumber = false
opt.number = true
opt.signcolumn = "yes"
opt.cursorlineopt = "number"
opt.confirm = true
opt.updatetime = 750
opt.splitbelow = true
opt.splitright = true
opt.timeoutlen = 400
opt.updatetime = 250
opt.undofile = true
opt.scrolloff = 10
opt.inccommand = "split"
opt.showmode = false
opt.shortmess:append "sI"

opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.breakat = "\t;:,!? "
opt.showbreak = "-->"

opt.clipboard:append "unnamedplus"

opt.completeopt = "menuone,noselect,fuzzy,nosort"
opt.complete = ".,w,b"

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

require "autocommands"
require("lazy").setup {
  defaults = { lazy = true },

  ui = {
    icons = {
      ft = "",
      lazy = "󰂠 ",
      loaded = "",
      not_loaded = "",
    },
  },

  performance = {
    rtp = {
      disabled_plugins = {
        "2html_plugin",
        "tohtml",
        "getscript",
        "getscriptPlugin",
        "gzip",
        "logipat",
        "matchit",
        "tar",
        "netrw",
        "netrwPlugin",
        "netrwFileManager",
        "netrwSettings",
        "tarPlugin",
        "rrhelper",
        "spellfile_plugin",
        "vimball",
        "vimballPlugin",
        "zip",
        "zipPlugin",
        "tutor",
        "rplugin",
        "syntax",
        "synmenu",
        "optwin",
        "compiler",
        "bugreport",
        "ftplugin",
      },
    },
  },
  spec = {
    { import = "plugins" },
  },
}

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

local imap_expr = function(lhs, rhs) vim.keymap.set("i", lhs, rhs, { expr = true }) end
imap_expr("<Tab>", [[pumvisible() ? "\<C-n>" : "\<Tab>"]])
imap_expr("<S-Tab>", [[pumvisible() ? "\<C-p>" : "\<S-Tab>"]])
_G.cr_action = function()
  -- If there is selected item in popup, accept it with <C-y>
  if vim.fn.complete_info()["selected"] ~= -1 then return "\25" end
  -- Fall back to plain `<CR>`. You might want to customize according
  -- to other plugins. For example if 'mini.pairs' is set up, replace
  -- next line with `return MiniPairs.cr()`
  return "\r"
end

vim.keymap.set("i", "<CR>", "v:lua.cr_action()", { expr = true })

require "lsp"
require "picker"
