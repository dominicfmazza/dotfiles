return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    input = { enabled = true },
    notifier = {
      margin = { top = 0, right = 1, bottom = 2 },
      top_down = false,
      enabled = true,
      style = "minimal",
    },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = false },
    scratch = { enabled = true, ft = "markdown" },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    styles = {
      notification = {
        border = "rounded",
        wo = {
          winblend = 5,
          wrap = false,
          conceallevel = 2,
          colorcolumn = "",
        },
      },
    },
  },
  keys = {
    -- FIND
    -- SCRATCH
    { "<leader>ss", function() require("snacks").scratch() end, desc = "Toggle Scratch Buffer" },
    { "<leader>so", function() require("snacks").scratch.select() end, desc = "Select Scratch Buffer" },
    -- GIT
    -- BUFFERS
    { "<leader>bf", function() require("snacks").picker.buffers() end, desc = "Buffers" },
    -- -- Other
    { "<leader>n", function() require("snacks").picker.notifications() end, desc = "Notification History" },
    { "<leader>Z", function() require("snacks").zen.zoom() end, desc = "Toggle Zoom" },
    { "<c-/>", function() require("snacks").terminal() end, desc = "Toggle Terminal" },
    { "<c-_>", function() require("snacks").terminal() end, desc = "which_key_ignore" },
    { "]]", function() require("snacks").words.jump(vim.v.count1) end, desc = "Next Reference", mode = { "n", "t" } },
    { "[[", function() require("snacks").words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },
  },
  init = function()
    local colortable = require("colors").colortable
    local borderhl = { fg = colortable.overlay0, bg = colortable.base }
    vim.api.nvim_set_hl(0, "FloatBorder", borderhl)
    vim.api.nvim_set_hl(0, "SnacksPickerBorder", borderhl)
    vim.api.nvim_set_hl(0, "SnacksPickerPreviewBorder", borderhl)
    vim.api.nvim_set_hl(0, "SnacksPickerListBorder", borderhl)
    vim.api.nvim_set_hl(0, "SnacksPickerInputBorder", borderhl)

    vim.api.nvim_set_hl(0, "SnacksPickerTitle", { bg = colortable.base, fg = colortable.text })
    vim.api.nvim_set_hl(0, "SnacksPickerPreview", { bg = colortable.base })
    vim.api.nvim_set_hl(0, "SnacksPickerList", { bg = colortable.base })
    vim.api.nvim_set_hl(0, "SnacksPickerListTitle", { bg = colortable.base, fg = colortable.text })
    vim.api.nvim_set_hl(0, "SnacksPickerInputTitle", { bg = colortable.base, fg = colortable.text })
    vim.api.nvim_set_hl(0, "SnacksPickerInputSearch", { bg = colortable.base, fg = colortable.text })
    vim.api.nvim_set_hl(0, "SnacksPickerInput", { bg = colortable.base })
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...) require("snacks").debug.inspect(...) end
        _G.bt = function() require("snacks").debug.backtrace() end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        -- Create some toggle mappings
        require("snacks").toggle.option("spell", { name = "Spelling" }):map "<leader>us"
        require("snacks").toggle.option("relativenumber", { name = "Relative Number" }):map "<leader>uL"
        require("snacks").toggle.diagnostics():map "<leader>ud"
        require("snacks").toggle.line_number():map "<leader>ul"
        require("snacks").toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map "<leader>uc"
        require("snacks").toggle.treesitter():map "<leader>uT"
        require("snacks").toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map "<leader>ub"
        require("snacks").toggle.inlay_hints():map "<leader>uh"
        require("snacks").toggle.indent():map "<leader>ug"
        require("snacks").toggle.dim():map "<leader>uD"
      end,
    })
  end,
}
