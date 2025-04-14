local has_words_before = function()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if col == 0 then return false end
  local line = vim.api.nvim_get_current_line()
  return line:sub(col, col):match "%s" == nil
end

return {
  "saghen/blink.cmp",
  priority = 900,
  dependencies = {
    {
      "L3MON4D3/LuaSnip",
      version = "v2.*",
      priority = 901,
      keys = function()
        -- Disable default tab keybinding in LuaSnip
        return {}
      end,
    },
    { "rafamadriz/friendly-snippets" },
  },
  version = "1.*",
  lazy = false,
  ---@module 'blink.cmp'
  opts = {
    keymap = {
      preset = "none",
      ["<Tab>"] = {
        function(cmp)
          if cmp.snippet_active() then return cmp.accept() end
          if has_words_before() and cmp.is_visible() then return cmp.insert_next() end
        end,
        "snippet_forward",
        "fallback",
      },
      ["<S-Tab>"] = { "insert_prev", "fallback" },
      ["<Enter>"] = { "accept", "fallback" },
    },
    appearance = {
      nerd_font_variant = "mono",
    },
    completion = {
      documentation = { auto_show = false },
      trigger = { show_in_snippet = false },
      list = { selection = { preselect = false }, cycle = { from_top = false } },
    },
    snippets = { preset = "luasnip" },
    sources = {
      default = { "lazydev", "lsp", "path", "snippets", "buffer" },
      providers = {
        cmdline = {
          -- ignores cmdline completions when executing shell commands
          enabled = function() return vim.fn.getcmdtype() ~= ":" or not vim.fn.getcmdline():match "^[%%0-9,'<>%-]*!" end,
        },
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          -- make lazydev completions top priority (see `:h blink.cmp`)
          score_offset = 100,
        },
        buffer = {
          opts = {
            get_bufnrs = vim.api.nvim_list_bufs,
          },
        },
      },
    },
    fuzzy = { implementation = "prefer_rust_with_warning" },
    cmdline = {
      completion = {
        menu = {
          auto_show = true,
        },
        list = {
          selection = {
            preselect = false,
          },
        },
      },
      keymap = {
        preset = "none",
        ["<Tab>"] = {
          "insert_next",
          "fallback",
        },
        ["<S-Tab>"] = { "insert_prev", "fallback" },
        ["<Enter>"] = { "accept_and_enter", "fallback" },
      },
    },
  },
  opts_extend = { "sources.default" },
}
