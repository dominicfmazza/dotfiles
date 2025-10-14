vim.pack.add { "https://github.com/benomahony/uv.nvim" }

require("uv").setup {
  keymaps = {
    prefix = "<leader>p",
  },
}
