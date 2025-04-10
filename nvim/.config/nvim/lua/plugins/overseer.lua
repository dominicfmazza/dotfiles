return {
  {
    lazy = false,
    "stevearc/overseer.nvim",
    opts = {},
    config = function()
      require("overseer").setup()
      require("overseer").load_template("cmakepresets")
    end
  },
}
