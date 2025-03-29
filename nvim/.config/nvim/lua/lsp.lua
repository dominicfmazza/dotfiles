local wk = require "which-key"
local snacks = require "snacks"

vim.lsp.enable {
  "luals",
  "clangd",
}

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
