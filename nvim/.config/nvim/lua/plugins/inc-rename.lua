return {
  "smjonas/inc-rename.nvim",
  lazy = false,
  config = function()
    require("inc_rename").setup { input_buffer_type = "dressing" }
  end,
}
