return {
  "danymat/neogen",
  config = function()
    local wk = require "which-key"
    wk.add {
      { "<leader>d", group = "Document" },
      noremap = true,
    }
    require("neogen").setup {
      languages = {
        ["cpp.doxygen"] = require "neogen.configurations.cpp",
      },
      snippet_engine = "luasnip",
    }
  end,
  keys = {
    {
      "<leader>d",
      function()
        require("neogen").generate()
      end,
      desc = "Generate documentation",
    },
  },
}
