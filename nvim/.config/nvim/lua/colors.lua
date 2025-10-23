vim.pack.add {
  "https://github.com/vague-theme/vague.nvim",
}

require("vague").setup {
  colors = {
    bg = "#0f0f0f",
    string = "#d6ca94"
  },
}

vim.cmd "colorscheme vague"
