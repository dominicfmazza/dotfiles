local lsp_capabilities = {
  workspace = { didChangeWatchedFiles = { dynamicRegistration = true } },
  textDocument = {
    foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    },
  },
}

vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(lsp_capabilities),
})

local lsps = {
  "luals",
  "clangd",
  "jsonls",
  "yamlls",
  "cmake",
  "bashls",
  "marksman",
  "dockerls",
  "basedpyright",
}
vim.lsp.enable(lsps)

vim.api.nvim_create_autocmd("LspDetach", {
  callback = function(args)
    -- Get the detaching client
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    -- Remove the autocommand to format the buffer on save, if it exists
    if client:supports_method "textDocument/formatting" then vim.api.nvim_clear_autocmds {
      event = "BufWritePre",
      buffer = args.buf,
    } end
  end,
})

vim.keymap.set("n", "<leader>lf", function() require("conform").format { async = true, lsp_fallback = true } end)

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function()
    vim.keymap.set("n", "<leader>ln", function() vim.lsp.buf.rename() end, { noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>ld", function() FzfLua.lsp_definitions() end, { noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>lD", function() FzfLua.lsp_declarations() end, { noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>lr", function() FzfLua.lsp_references() end, { nowait = true, noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>li", function() FzfLua.lsp_implementations() end, { noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>lt", function() FzfLua.lsp_typedefs() end, { noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>lS", function() FzfLua.lsp_document_symbols() end, { noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>ls", function() FzfLua.lsp_workspace_symbols() end, { noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>lx", function() FzfLua.lsp_document_diagnostics() end, { noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>lX", function() FzfLua.lsp_workspace_diagnostics() end, { noremap = true, buffer = true })
    vim.keymap.set("n", "<leader>a", function() vim.lsp.buf.code_action() end, { noremap = true, buffer = true })
    vim.keymap.set("n", "<C-k>", vim.lsp.buf.hover, { noremap = true, buffer = true })
    vim.keymap.set("n", "<C-s>", vim.lsp.buf.signature_help, { noremap = true, buffer = true })
  end,
})

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
