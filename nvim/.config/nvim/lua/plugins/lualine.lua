return {
  "bluz71/nvim-linefly",
  lazy = false,
  config = function()
    vim.opt.laststatus = 3
    vim.g.linefly_options = {
      winbar = true,
    }
  end,
}
