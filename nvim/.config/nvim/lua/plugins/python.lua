return {
  {
    "benomahony/uv.nvim",
    lazy = false,
    config = function() require("uv").setup() end,
  },
  {
    "mfussenegger/nvim-dap-python",
    config = function() require("dap-python").setup "uv" end,
  },
}
