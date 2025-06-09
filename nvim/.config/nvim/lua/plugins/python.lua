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
  {
    "mfussenegger/nvim-dap-python",
    config = function() require("dap-python").setup "uv" end,
  },
}
