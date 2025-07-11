return {
  {
    "benomahony/uv.nvim",
    lazy = false,
    config = function()
      require("uv").setup {
        keymaps = {
          prefix = "<leader>p",
        },
      }
    end,
  },
}
