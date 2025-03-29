local has_words_before = function()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if col == 0 then return false end
  local line = vim.api.nvim_get_current_line()
  return line:sub(col, col):match "%s" == nil
end

return {
  "saghen/blink.cmp",
  dependencies = { "rafamadriz/friendly-snippets" },
  version = "1.*",
  lazy = false,
  ---@module 'blink.cmp'
  opts = {
    keymap = {
      preset = "none",
      ["<Tab>"] = {
        function(cmp)
          if has_words_before() then return cmp.insert_next() end
        end,
        "fallback",
      },
      ["<S-Tab>"] = { "insert_prev" },
      ["<Enter>"] = { "accept", "fallback" },
    },
    appearance = {
      nerd_font_variant = "mono",
    },
    completion = {
      documentation = { auto_show = false },
      list = { selection = { preselect = false }, cycle = { from_top = false } },
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
      providers = {
        cmdline = {
          -- ignores cmdline completions when executing shell commands
          enabled = function() return vim.fn.getcmdtype() ~= ":" or not vim.fn.getcmdline():match "^[%%0-9,'<>%-]*!" end,
        },
      },
    },
    fuzzy = { implementation = "prefer_rust_with_warning" },
    cmdline = {
      keymap = {
        preset = "none",
        ["<Tab>"] = {
          function(cmp)
            if has_words_before() then return cmp.insert_next() end
          end,
          "fallback",
        },
        ["<S-Tab>"] = { "insert_prev" },
        ["<Enter>"] = { "accept_and_enter", "fallback" },
      },
    },
  },
  opts_extend = { "sources.default" },
}
