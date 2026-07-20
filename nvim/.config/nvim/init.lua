vim.g.mapleader = " "
vim.g.have_nerd_font = true

local opt = vim.opt
opt.title = true
opt.titlestring = vim.fs.basename(vim.fn.getcwd())

vim.env.NVR_SERVER = vim.v.servername

-- global options --
opt.incsearch = true -- Find the next match as we type the search
opt.hlsearch = true -- Hilight searches by default
opt.viminfo = "'100,f1" -- Save up to 100 marks, enable capital marks
opt.ignorecase = true -- Ignore case when searching...
opt.smartcase = true -- ...unless we type a capital
opt.autoindent = true
opt.smartindent = true
opt.expandtab = true
opt.tabstop = 4
opt.scroll = 5
opt.shiftwidth = 4
opt.termguicolors = true
opt.cursorline = true
opt.relativenumber = true
opt.number = true
opt.signcolumn = "yes"
opt.cursorline = true
-- opt.cursorlineopt = "number"
opt.confirm = true
opt.splitbelow = true
opt.splitright = true
opt.timeoutlen = 400
opt.updatetime = 60
opt.undofile = true
opt.scrolloff = 10
opt.inccommand = "split"
opt.showmode = false
opt.shortmess:append "sI"
opt.winbar = "%f"
opt.exrc = true

require("vim._core.ui2").enable {}

-- system clipboard

opt.shell = "/usr/bin/env zsh"

-- WRAP --
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.breakat = "\t;:,!? "
opt.showbreak = "-->"

-- GLOBAL STATUSLINE --
opt.laststatus = 3

if vim.g.neovide then
  vim.o.guifont = "Hack Nerd Font:h12"
  vim.g.neovide_text_contrast = 0.7
end

local gh = function(repository) return "https://github.com/" .. repository end

vim.pack.add {
  gh "nvim-mini/mini.nvim",
  gh "rachartier/tiny-inline-diagnostic.nvim",
  gh "rachartier/tiny-code-action.nvim",
  gh "lewis6991/gitsigns.nvim",
  gh "luukvbaal/statuscol.nvim",
  gh "stevearc/conform.nvim",
  gh "kevinhwang91/nvim-bqf",
  { src = gh "nvim-treesitter/nvim-treesitter", version = "main" },
  gh "nvim-lua/plenary.nvim",
  gh "jiaoshijie/undotree",
  gh "nvim-neo-tree/neo-tree.nvim",
  gh "nvim-tree/nvim-web-devicons",
  gh "MunifTanjim/nui.nvim",
  gh "mrcjkb/rustaceanvim.git",
  gh "ibhagwan/fzf-lua",
  gh "danymat/neogen",
  { src = gh "saghen/blink.cmp", version = vim.version.range ">1.0.0" },
  gh "obsidian-nvim/obsidian.nvim",
  gh "MeanderingProgrammer/render-markdown.nvim.git",
  gh "waiting-for-dev/ergoterm.nvim",
  gh "3rd/image.nvim",
  gh "3rd/diagram.nvim",
}

local map = vim.keymap.set
require "colors"
require "keymaps"

vim.diagnostic.config {
  virtual_text = false,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "󰌵",
    },
  },
}

require("tiny-inline-diagnostic").setup {
  options = {
    show_source = {
      if_many = true,
    },
    multilines = {
      enabled = true,
      always_show = true,
    },
  },
}

map("n", "<leader>u", function() require("undotree").toggle() end)

require("statuscol").setup()

require("conform").setup {
  formatters_by_ft = {
    lua = { "stylua" },
    cpp = { "clang_format" },
    cmake = { "gersemi" },
    python = { "black" },
    bash = { "beautysh" },
    markdown = { "prettierd" },
    html = { "prettierd" },
    css = { "prettierd" },
    js = { "prettierd" },
    json = { "jq" },
    yaml = { "yamlfmt" },
    rust = { "rustfmt" },
  },
}

require("neo-tree").setup {
  filesystem = {
    filtered_items = {
      hide_dotfiles = false,
    },
  },
}

require("mini.icons").setup()
require("mini.icons").tweak_lsp_kind()
require("mini.ai").setup()
require("mini.align").setup()
require("mini.hipatterns").setup {
  highlighters = {
    -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
    fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
    hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
    todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
    note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },

    -- Highlight hex color strings (`#rrggbb`) using that color
    hex_color = require("mini.hipatterns").gen_highlighter.hex_color(),
  },
}
require("mini.extra").setup()
require("mini.statusline").setup()
require("mini.jump").setup {
  delay = { highlight = 1e7 },
}

require("mini.notify").setup()
local opts = { ERROR = { duration = 10000 } }
vim.notify = require("mini.notify").make_notify(opts)

require("mini.snippets").setup()

require("render-markdown").setup {
  completions = { lsp = { enabled = true } },
}

require("neogen").setup()
local ngopts = { noremap = true, silent = true }
vim.api.nvim_set_keymap("n", "<Leader>nf", ":lua require('neogen').generate()<CR>", ngopts)

require "term"
require "tabline"
require "git"
require "lsp"
require "picker"
require "autocommands"
require "obsidian_setup"
require "treesitter"
require "quickfix"
require "clipboard"
