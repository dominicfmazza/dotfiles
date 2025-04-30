local opt = vim.opt

vim.cmd.colorscheme "catppuccin-mocha"

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
opt.relativenumber = true
opt.number = true
opt.signcolumn = "yes"
opt.cursorlineopt = "number"
opt.wrap = false
opt.updatetime = 750
opt.splitbelow = true
opt.splitright = true
opt.timeoutlen = 400
opt.undofile = true
opt.sessionoptions="blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

vim.g.smart_motion_log_level = "debug"

opt.clipboard:append "unnamedplus"
vim.g.clipboard = 'osc52'
