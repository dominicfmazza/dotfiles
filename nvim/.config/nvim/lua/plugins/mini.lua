return {
  "echasnovski/mini.nvim",
  version = "*",
  lazy = false,
  config = function()
    require("mini.ai").setup()
    require("mini.align").setup()
    require("mini.hipatterns").setup {
      highlighters = {
        -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
        fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
        hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
        todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
        note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },

        -- Highlight hex color strings (`#rrggbb`) using that color
        hex_color = require("mini.hipatterns").gen_highlighter.hex_color(),
      },
    }
  end,
}
