return {
  "LintaoAmons/scratch.nvim",
  event = "VeryLazy",
  config = function()
    require("scratch").setup {
      use_telescope = false,
      filepicker = "fzflua",
      filetypes = { "py", "md", "lua", "js", "sh", "ts" }, -- you can simply put filetype here
    }
    local wk = require "which-key"
    wk.add {
      { "<leader>s", group = "Scratch Space" },
      noremap = true,
    }
  end,
  keys = {
    {
      "<leader>ss",
      "<cmd>Scratch<cr>",
      desc = "Open Scratch File",
    },
    {
      "<leader>so",
      "<cmd>ScratchOpen<cr>",
      desc = "Open Existing Scratch File",
    }
  },
}
