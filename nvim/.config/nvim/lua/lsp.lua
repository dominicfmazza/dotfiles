require("blink.cmp").setup {
  keymap = {
    preset = "none",
    ["<C-s>"] = { "show_signature", "hide_signature", "fallback" },
    ["<C-e>"] = { "hide", "fallback" },
    ["<CR>"] = { "accept", "fallback" },
    ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
    ["<Up>"] = { "select_prev", "fallback" },
    ["<Down>"] = { "select_next", "fallback" },
    ["<C-up>"] = { "scroll_documentation_up", "fallback" },
    ["<C-down>"] = { "scroll_documentation_down", "fallback" },
  },
  completion = { documentation = { auto_show = false }, list = { selection = { preselect = false }, cycle = { from_top = false } } },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
    providers = {
      buffer = {
        opts = {
          get_bufnrs = function()
            return vim.tbl_filter(function(bufnr) return vim.bo[bufnr].buftype == "" end, vim.api.nvim_list_bufs())
          end,
        },
      },
    },
  },
  fuzzy = {
    implementation = "prefer_rust_with_warning",
  },
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
  signature = { enabled = true },
}

vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

local lsps = {
  "luals",
  "clangd",
  "jsonls",
  "yamlls",
  "cmake",
  "bashls",
  "dockerls",
  "basedpyright",
}
vim.lsp.enable(lsps)

vim.keymap.set("n", "<leader>lf", function() require("conform").format { async = true, lsp_fallback = true } end)

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function()
    vim.keymap.set("n", "<leader>ln", function() vim.lsp.buf.rename() end, { desc = "Rename", noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>ld", function() FzfLua.lsp_definitions() end, { desc = "Definitions", noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>lD", function() FzfLua.lsp_declarations() end, { desc = "Declarations", noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>lr", function() FzfLua.lsp_references() end, { desc = "References", nowait = true, noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>li", function() FzfLua.lsp_implementations() end, { desc = "Implementations", noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>lt", function() FzfLua.lsp_typedefs() end, { desc = "Typedefs", noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>lS", function() FzfLua.lsp_document_symbols() end, { desc = "Document Symbols", noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>ls", function() FzfLua.lsp_workspace_symbols() end, { desc = "Workspace Symbols", noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>lx", function() FzfLua.lsp_document_diagnostics() end, { desc = "Document Diagnostics", noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>lX", function() FzfLua.lsp_workspace_diagnostics() end, { desc = "Workspace Diagnostics", noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>a", function() vim.lsp.buf.code_action() end, { desc = "Code Actions", noremap = true, buffer = true })
    vim.keymap.set("n", "<C-k>", function() vim.lsp.buf.hover() end, { desc = "LSP Hover", noremap = true, buffer = true })
  end,
})

vim.api.nvim_create_user_command("LspInfo", ":checkhealth vim.lsp", { desc = "Alias to `:checkhealth vim.lsp`" })

vim.api.nvim_create_user_command("LspLog", function()
  local log = vim.lsp.log.get_filename()
  vim.cmd("e " .. log)
end, {})
