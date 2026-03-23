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

require("vim._core.ui2").enable {}

-- system clipboard
vim.opt.clipboard:append "unnamedplus"
-- Fix "waiting for osc52 response from terminal" message
-- https://github.com/neovim/neovim/issues/28611
if vim.env.SSH_TTY ~= nil then
  -- Set up clipboard for ssh
  local function my_paste(_)
    return function(_)
      local content = vim.fn.getreg '"'
      return vim.split(content, "\n")
    end
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy "+",
      ["*"] = require("vim.ui.clipboard.osc52").copy "*",
    },
    paste = {
      -- No OSC52 paste action since wezterm doesn't support it
      -- Should still paste from nvim
      ["+"] = my_paste "+",
      ["*"] = my_paste "*",
    },
  }
end

opt.shell = "/usr/bin/env zsh"

-- WRAP --
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.breakat = "\t;:,!? "
opt.showbreak = "-->"

-- GLOBAL STATUSLINE --
opt.laststatus = 3

if vim.g.neovide then require "neovide" end

vim.pack.add {
  "https://github.com/nvim-mini/mini.nvim",
  "https://github.com/rachartier/tiny-inline-diagnostic.nvim",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/luukvbaal/statuscol.nvim",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/kevinhwang91/nvim-bqf",
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/jiaoshijie/undotree",
  "https://github.com/nvim-neo-tree/neo-tree.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/mrcjkb/rustaceanvim.git",
  "https://github.com/ibhagwan/fzf-lua",
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range ">1.0.0" },
  "https://github.com/obsidian-nvim/obsidian.nvim",
  "https://github.com/MeanderingProgrammer/render-markdown.nvim.git",
  "https://github.com/waiting-for-dev/ergoterm.nvim",
  { src = "https://github.com/mistweaverco/bafa.nvim.git", version = "v1.10.1" },
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


require "term"
require "tabline"
require "git"
require "lsp"
require "picker"
require "autocommands"
require "obsidian_setup"
require "treesitter"
require "quickfix"
