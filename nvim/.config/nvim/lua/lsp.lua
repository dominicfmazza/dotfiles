local wk = require "which-key"
local snacks = require "snacks"

vim.lsp.config("*", {
  capabilities = {
    workspace = { didChangeWatchedFiles = { dynamicRegistration = true } },
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
  "bashls",
  "marksman",
  "dockerls",
  "basedpyright",
}
vim.lsp.enable(lsps)

wk.add {
  { "gr", group = "+LSP" },
  {
    "grf",
    function() require("conform").format { async = true, lsp_fallback = true } end,
    desc = "Format",
  },
  { "grn", function() vim.lsp.buf.rename() end, desc = "LSP: Rename" },
  { "grd", function() snacks.picker.lsp_definitions() end, desc = "LSP: Goto Definition" },
  { "grD", function() snacks.picker.lsp_declarations() end, desc = "LSP: Goto Declaration" },
  { "grr", function() snacks.picker.lsp_references() end, nowait = true, desc = "LSP: References" },
  { "gri", function() snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
  { "grt", function() snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
  { "grs", function() snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
  { "grS", function() snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
  { "gra", vim.lsp.buf.code_action, desc = "LSP: Code Action" },
  { "<C-k>", vim.lsp.buf.hover, desc = "LSP: Hover LSP Help" },
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

vim.api.nvim_create_user_command("LspStop", function(args)
  local arg1 = args.fargs[1] or ""
  local lsp_clients = vim.lsp.get_clients()
  if not arg1 == "" then lsp_clients = vim.lsp.get_clients { name = arg1 } end
  vim.lsp.stop_client(lsp_clients)
  vim.wait(1000)
  vim.cmd "edit"
end, { nargs = "*" })

local empty = function(tab)
  for _, _ in pairs(tab) do
    return false
  end
  return true
end

vim.api.nvim_create_user_command("LspRestart", function(args)
  local arg1 = args.fargs[1] or ""
  if not arg1 == "" then
    vim.cmd("LspStop  " .. arg1)
    vim.cmd("LspStart " .. arg1)
  else
    local lsp_clients = vim.lsp.get_clients()
    if not empty(lsp_clients) then
      vim.cmd "LspStop"
      vim.cmd "LspStart"
    end
  end
end, { nargs = "*" })

vim.api.nvim_create_user_command("LspLog", function()
  local log = vim.lsp.log.get_filename()
  vim.cmd("e " .. log)
end, {})
