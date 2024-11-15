-- lazy.nvim
return {
  "m4xshen/hardtime.nvim",
  dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
  lazy = false,
  opts = {
    resetting_keys = { ["j"] = { "n", "x" }, ["k"] = { "n", "x" } },
  },
}
