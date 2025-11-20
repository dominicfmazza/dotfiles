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
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.termguicolors = true
opt.cursorline = true
opt.relativenumber = false
opt.number = true
opt.signcolumn = "yes"
opt.cursorlineopt = "number"
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

opt.clipboard:append "unnamedplus"

opt.shell = "/usr/bin/env zsh"

-- WRAP --
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.breakat = "\t;:,!? "
opt.showbreak = "-->"

-- GLOBAL STATUSLINE --
opt.laststatus = 3

vim.pack.add {
  "https://github.com/nvim-mini/mini.nvim",
  "https://github.com/rachartier/tiny-inline-diagnostic.nvim",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/luukvbaal/statuscol.nvim",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/stevearc/quicker.nvim",
  "https://github.com/nmac427/guess-indent.nvim",
  "https://github.com/christoomey/vim-tmux-navigator",
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/jiaoshijie/undotree",
  "https://github.com/nvim-neo-tree/neo-tree.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/ibhagwan/fzf-lua",
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range ">1.0.0" },
  "https://github.com/obsidian-nvim/obsidian.nvim",
  "https://github.com/MeanderingProgrammer/render-markdown.nvim.git",
  "https://github.com/stevearc/overseer.nvim.git",
  "https://github.com/sindrets/diffview.nvim",
  "https://github.com/sphamba/smear-cursor.nvim",
}

local map = vim.keymap.set
require "colors"

require("smear_cursor").setup {
  stiffness = 0.8,
  trailing_stiffness = 0.5,
  distance_stop_animating = 0.5,
  legacy_computing_symbols_support = true
}

require("quicker").setup {
  opts = { wrap = true },
}
map("n", "<leader>vq", function() require("quicker").toggle() end, {
  desc = "Toggle quickfix",
})
map("n", "<leader>vl", function() require("quicker").toggle { loclist = true } end, {
  desc = "Toggle loclist",
})
require("gitsigns").setup {
  signcolumn = true,
  signs = {
    delete = { text = "󰍵" },
    changedelete = { text = "󱕖" },
  },
}

map("n", "<leader>gS", function() require("gitsigns").stage_buffer() end, { desc = "Stage Buffer", noremap = true })
map("n", "<leader>gd", function() require("gitsigns").diffthis() end, { desc = "Diff This", noremap = true })
map("n", "<leader>gh", function() require("gitsigns").reset_hunk() end, { desc = "Reset Hunk", noremap = true })
map("n", "<leader>gl", function() require("gitsigns").blame_line() end, { desc = "Blame Line", noremap = true })
map("n", "<leader>gp", function() require("gitsigns").preview_hunk() end, { desc = "Preview Hunk", noremap = true })
map("n", "<leader>gr", function() require("gitsigns").reset_buffer() end, { desc = "Reset Buffer", noremap = true })
map("n", "<leader>gs", function() require("gitsigns").stage_hunk() end, { desc = "Stage Hunk", noremap = true })
map("n", "<leader>gu", function() require("gitsigns").undo_stage_hunk() end, { desc = "Undo Stage Hunk", noremap = true })
map("n", "]g", function() require("gitsigns").next_hunk() end, { desc = "Next Git Hunk", noremap = true })
map("n", "[g", function() require("gitsigns").prev_hunk() end, { desc = "Previous Git Hunk", noremap = true })

require("nvim-treesitter.configs").setup {
  ensure_installed = {
    "vim",
    "lua",
    "vimdoc",
    "luadoc",
    "query",
    "cpp",
    "cuda",
    "c",
    "cmake",
    "yaml",
    "python",
    "markdown",
    "markdown_inline",
    "bash",
    "regex",
  },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = true,
  },
}

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
    json = { "jq" },
    yaml = { "yamlfmt" },
    rust = { "rustfmt" },
  },
}

require("guess-indent").setup()

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
  },
}

require("render-markdown").setup {
  completions = { lsp = { enabled = true } },
}

require("overseer").setup()

vim.g.tmux_navigator_no_mappings = 1
vim.g.tmux_navigator_no_wrap = 1
map("n", "<M-h>", "<cmd>TmuxNavigateLeft<cr>")
map("n", "<M-j>", "<cmd>TmuxNavigateDown<cr>")
map("n", "<M-k>", "<cmd>TmuxNavigateUp<cr>")
map("n", "<M-l>", "<cmd>TmuxNavigateRight<cr>")
map("n", "<M-\\>", "<cmd>TmuxNavigatePrevious<cr>")

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "General Clear highlights" })
map("n", "<C-[>", "<cmd>noh<CR>", { desc = "General Clear highlights" })

map("n", "<leader>c", "<cmd>close<cr>", { desc = "Close buffer" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Write" })
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

map("n", "<leader>e", "<cmd>Neotree focus filesystem toggle<cr>", { noremap = true })

require "lsp"
require "picker"
require "autocommands"
require "obsidian_setup"
