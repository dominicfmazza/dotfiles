return {
  "folke/flash.nvim",
  event = "VeryLazy",
  config = function()
    require("flash").setup {
      modes = {
        char = {
          jump_labels = true,
          highlight = { backdrop = true},
        },
      },
    }
  end,
  -- stylua: ignore
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
  },
}
