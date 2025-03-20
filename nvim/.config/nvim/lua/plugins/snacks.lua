return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    indent = { enabled = true, animate = { enabled = false } },
    input = { enabled = true },
    picker = { enabled = true, sources = { explorer = { auto_close = true, layout = { preset = "sidebar" } } } },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    styles = { notification = { border = "top", zindex = 100, ft = "markdown", wo = { winblend = 5, wrap = false, conceallevel = 2, colorcolumn = "" }, bo = { filetype = "snacks_notif" } } },
  },
  keys = {
    -- FIND
    { "<leader>ff", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
    { "<leader>fb", function() Snacks.picker.grep_buffers() end, desc = "Grep in Buffers" },
    { "<leader>fg", function() Snacks.picker.grep() end, desc = "Grep" },
    { "<leader>f:", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader>fw", function() Snacks.picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" } },
    -- { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" }, -- Add back when TODO works with Snacks
    { '<leader>f"', function() Snacks.picker.registers() end, desc = "Registers" },
    { "<leader>f/", function() Snacks.picker.search_history() end, desc = "Search History" },
    { "<leader>fa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
    { "<leader>fb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
    { "<leader>fc", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader>fC", function() Snacks.picker.commands() end, desc = "Commands" },
    { "<leader>fd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
    { "<leader>fD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
    { "<leader>fh", function() Snacks.picker.help() end, desc = "Help Pages" },
    { "<leader>fH", function() Snacks.picker.highlights() end, desc = "Highlights" },
    { "<leader>fi", function() Snacks.picker.icons() end, desc = "Icons" },
    { "<leader>fj", function() Snacks.picker.jumps() end, desc = "Jumps" },
    { "<leader>fm", function() Snacks.picker.marks() end, desc = "Marks" },
    { "<leader>fM", function() Snacks.picker.man() end, desc = "Man Pages" },
    { "<leader>fp", function() Snacks.picker.lazy() end, desc = "Search for Plugin Spec" },
    { "<leader>fq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
    { "<leader>fR", function() Snacks.picker.resume() end, desc = "Resume" },
    { "<leader>fu", function() Snacks.picker.undo() end, desc = "Undo History" },
    -- SCRATCH
    { "<leader>ss", function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
    { "<leader>so", function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
    -- GIT
    { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
    { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse", mode = { "n", "v" } },
    { "<leader>gb", function() Snacks.picker.git_branches() end, desc = "Git Branches" },
    { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Git Log" },
    { "<leader>gL", function() Snacks.picker.git_log_line() end, desc = "Git Log Line" },
    { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git Status" },
    { "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Git Stash" },
    { "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Git Diff (Hunks)" },
    { "<leader>gf", function() Snacks.picker.git_log_file() end, desc = "Git Log File" },
    -- LSP
    { "<leader>ld", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
    { "<leader>lD", function() Snacks.picker.lsp_declarations() end, desc = "Goto Declaration" },
    { "<leader>lR", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
    { "<leader>li", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
    { "<leader>lt", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
    { "<leader>ls", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
    { "<leader>lS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
    -- BUFFERS
    { "<leader>bf", function() Snacks.picker.buffers() end, desc = "Buffers" },
    -- -- Other
    { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
    { "<leader>Z", function() Snacks.zen.zoom() end, desc = "Toggle Zoom" },
    { "<c-/>", function() Snacks.terminal() end, desc = "Toggle Terminal" },
    { "<c-_>", function() Snacks.terminal() end, desc = "which_key_ignore" },
    { "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference", mode = { "n", "t" } },
    { "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...) Snacks.debug.inspect(...) end
        _G.bt = function() Snacks.debug.backtrace() end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        -- Create some toggle mappings
        Snacks.toggle.option("spell", { name = "Spelling" }):map "<leader>us"
        Snacks.toggle.option("wrap", { name = "Wrap" }):map "<leader>uw"
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map "<leader>uL"
        Snacks.toggle.diagnostics():map "<leader>ud"
        Snacks.toggle.line_number():map "<leader>ul"
        Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map "<leader>uc"
        Snacks.toggle.treesitter():map "<leader>uT"
        Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map "<leader>ub"
        Snacks.toggle.inlay_hints():map "<leader>uh"
        Snacks.toggle.indent():map "<leader>ug"
        Snacks.toggle.dim():map "<leader>uD"
      end,
    })
  end,
}
