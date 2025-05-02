return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    indent = { enabled = true, animate = { enabled = false } },
    input = { enabled = true },
    image = { enabled = true },
    picker = {
      enabled = true,
      layout = {
        -- The default layout for "telescopy" pickers, e.g. `files`, `commands`, ...
        -- It will not override non-standard pickers, e.g. `explorer`, `lines`, ...
        preset = function() return vim.o.columns >= 120 and "telescope" or "vertical" end,
      },
      layouts = {
        telescope = {
          -- Copy from https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#telescope
          reverse = false,
          layout = {
            box = "horizontal",
            backdrop = false,
            height = 0.8,
            width = 0.7,
            border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
            {
              box = "vertical",
              {
                title = "Find {title} {live} {flags}",
                win = "list",
                border = { "┌", "─", "┐", "│", "┤", "─", "├", "│" },
              },
              { win = "input", border = { "", "", "", "│", "┘", "─", "└", "│" }, height = 1 },
            },
            {
              win = "preview",
              title = "{preview:Preview}",
              width = 0.51, -- Change the preview width
              border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
              title_pos = "center",
            },
          },
        },
      },
      sources = {
        files = {},
        lines = {
          layout = {
            preset = function() return vim.o.columns >= 120 and "telescope" or "vertical" end,
          },
        },
      },
    },
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
    styles = { notification = { border = "top", zindex = 100, ft = "markdown", wo = { winblend = 5, wrap = false, conceallevel = 2, colorcolumn = "" }, bo = { filetype = "snacks_notif" } } },
  },
  keys = {
    -- FIND
    { "<leader>ff", function() require("snacks").picker.files({hidden = true}) end, desc = "Smart Find Files" },
    { "<leader>fb", function() require("snacks").picker.grep_buffers() end, desc = "Grep in Buffers" },
    { "<leader>fg", function() require("snacks").picker.grep() end, desc = "Grep" },
    { "<leader>f:", function() require("snacks").picker.command_history() end, desc = "Command History" },
    { "<leader>fw", function() require("snacks").picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" } },
    { '<leader>f"', function() require("snacks").picker.registers() end, desc = "Registers" },
    { "<leader>f/", function() require("snacks").picker.search_history() end, desc = "Search History" },
    { "<leader>fa", function() require("snacks").picker.autocmds() end, desc = "Autocmds" },
    { "<leader>fb", function() require("snacks").picker.lines() end, desc = "Buffer Lines" },
    { "<leader>fc", function() require("snacks").picker.command_history() end, desc = "Command History" },
    { "<leader>fC", function() require("snacks").picker.commands() end, desc = "Commands" },
    { "<leader>fd", function() require("snacks").picker.diagnostics() end, desc = "Diagnostics" },
    { "<leader>fD", function() require("snacks").picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
    { "<leader>fh", function() require("snacks").picker.help() end, desc = "Help Pages" },
    { "<leader>fH", function() require("snacks").picker.highlights() end, desc = "Highlights" },
    { "<leader>fi", function() require("snacks").picker.icons() end, desc = "Icons" },
    { "<leader>fj", function() require("snacks").picker.jumps() end, desc = "Jumps" },
    { "<leader>fm", function() require("snacks").picker.marks() end, desc = "Marks" },
    { "<leader>fM", function() require("snacks").picker.man() end, desc = "Man Pages" },
    { "<leader>fp", function() require("snacks").picker.lazy() end, desc = "Search for Plugin Spec" },
    { "<leader>fq", function() require("snacks").picker.qflist() end, desc = "Quickfix List" },
    { "<leader>fR", function() require("snacks").picker.resume() end, desc = "Resume" },
    { "<leader>fu", function() require("snacks").picker.undo() end, desc = "Undo History" },
    { "<leader>fk", function() require("snacks").picker.keymaps() end, desc = "Keymaps" },
    -- SCRATCH
    { "<leader>ss", function() require("snacks").scratch() end, desc = "Toggle Scratch Buffer" },
    { "<leader>so", function() require("snacks").scratch.select() end, desc = "Select Scratch Buffer" },
    -- GIT
    { "<leader>gg", function() require("snacks").lazygit() end, desc = "Lazygit" },
    { "<leader>gB", function() require("snacks").gitbrowse() end, desc = "Git Browse", mode = { "n", "v" } },
    { "<leader>gb", function() require("snacks").picker.git_branches() end, desc = "Git Branches" },
    { "<leader>gl", function() require("snacks").picker.git_log() end, desc = "Git Log" },
    { "<leader>gL", function() require("snacks").picker.git_log_line() end, desc = "Git Log Line" },
    { "<leader>gs", function() require("snacks").picker.git_status() end, desc = "Git Status" },
    { "<leader>gS", function() require("snacks").picker.git_stash() end, desc = "Git Stash" },
    { "<leader>gd", function() require("snacks").picker.git_diff() end, desc = "Git Diff (Hunks)" },
    { "<leader>gf", function() require("snacks").picker.git_log_file() end, desc = "Git Log File" },
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
    vim.api.nvim_set_hl(0, "FloatBorder", { fg = colortable.base, bg = colortable.base })
    vim.api.nvim_set_hl(0, "SnacksPickerTitle", { bg = colortable.base, fg = colortable.text })
    vim.api.nvim_set_hl(0, "SnacksPickerPreview", { bg = colortable.base })
    vim.api.nvim_set_hl(0, "SnacksPickerPreviewBorder", { bg = colortable.base, fg = colortable.surface2 })
    vim.api.nvim_set_hl(0, "SnacksPickerList", { bg = colortable.base })
    vim.api.nvim_set_hl(0, "SnacksPickerBorder", { bg = colortable.base, fg = colortable.base })
    vim.api.nvim_set_hl(0, "SnacksPickerListBorder", { bg = colortable.base, fg = colortable.surface2 })
    vim.api.nvim_set_hl(0, "SnacksPickerListTitle", { bg = colortable.base, fg = colortable.text })
    vim.api.nvim_set_hl(0, "SnacksPickerInputTitle", { bg = colortable.base, fg = colortable.text })
    vim.api.nvim_set_hl(0, "SnacksPickerInputBorder", { bg = colortable.base, fg = colortable.surface2 })
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
        require("which-key").add {
          "<leader>uw",
          function() require("wrap").ToggleWrap() end,
          icon = function()
            local state = require("wrap").wrapenabled
            return { icon = state and " " or " ", color = state and "green" or "yellow" }
          end,
          desc = function() return require("wrap").wrapenabled and "Disable wrap" or "Enable wrap" end,
        }
      end,
    })
  end,
}
