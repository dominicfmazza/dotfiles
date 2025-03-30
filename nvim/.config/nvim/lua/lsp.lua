local wk = require "which-key"
local snacks = require "snacks"

vim.lsp.config("*", {
  capabilities = {
    workspace = { didChangeWatchedFiles = { dynamicRegistration = false } },
    textDocument = {
      foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      },
    },
  },
})

local lsps = {
  "luals",
  "clangd",
  "jsonls",
  "yamlls",
}
vim.lsp.enable(lsps)

wk.add {
  { "gr", group = "+LSP" },
  {
    "grf",
    function() require("conform").format { lsp_fallback = true } end,
    desc = "Format",
  },
  { "grn", function() vim.lsp.buf.rename() end, desc = "LSP: Rename" },
  { "grd", function() snacks.picker.lsp_definitions() end, desc = "LSP: Goto Definition" },
  { "grD", function() snacks.picker.lsp_declarations() end, desc = "LSP: Goto Declaration" },
  { "grR", function() snacks.picker.lsp_references() end, nowait = true, desc = "LSP: References" },
  { "gri", function() snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
  { "grt", function() snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
  { "grs", function() snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
  { "grS", function() snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
  { "gra", vim.lsp.buf.code_action, desc = "LSP: Code Action" },
  { "grk", vim.lsp.buf.hover, desc = "LSP: Hover LSP Help" },
  { "<C-s>", vim.lsp.buf.signature_help, desc = "LSP Signature Help" },
  noremap = true,
}

vim.api.nvim_create_user_command("LspInfo", ":checkhealth vim.lsp", { desc = "Alias to `:checkhealth vim.lsp`" })

vim.api.nvim_create_user_command("LspStart", function(args)
  local arg1 = args.fargs[1] or ""

  if arg1 == "" then
    vim.lsp.enable(lsps)
  else
    vim.lsp.enable(arg1)
  end

  vim.cmd "edit"
end, {
  nargs = "*",
  complete = function() return lsps end,
})

vim.api.nvim_create_user_command("LspStop", function()
  vim.lsp.stop_client(vim.lsp.get_clients())
  vim.wait(500)
  vim.cmd "edit"
end, {})

vim.api.nvim_create_user_command("LspRestart", function()
  vim.cmd "LspStop"
  vim.cmd "LspStart"
end, {})

vim.api.nvim_create_user_command("LspLog", function()
  local log = vim.lsp.log.get_filename()
  vim.cmd("e " .. log)
end, {})
