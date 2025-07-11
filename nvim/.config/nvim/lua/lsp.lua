local wk = require "which-key"

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
  "bashls",
  "marksman",
  "dockerls",
  "basedpyright",
}
vim.lsp.enable(lsps)

wk.add {
  { "<leader>l", group = "+LSP" },
}

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

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    wk.add {
      {
        "<leader>lf",
        function() require("conform").format { async = true, lsp_fallback = true } end,
        desc = "Format",
      },
      { "<leader>ln", function() vim.lsp.buf.rename() end, desc = "LSP: Rename" },
      { "<leader>ld", function() FzfLua.lsp_definitions() end, desc = "LSP: Goto Definition" },
      { "<leader>lD", function() FzfLua.lsp_declarations() end, desc = "LSP: Goto Declaration" },
      { "<leader>lr", function() FzfLua.lsp_references() end, nowait = true, desc = "LSP: References" },
      { "<leader>li", function() FzfLua.lsp_implementations() end, desc = "Goto Implementation" },
      { "<leader>lt", function() FzfLua.lsp_typedefs() end, desc = "Goto T[y]pe Definition" },
      { "<leader>lS", function() FzfLua.lsp_document_symbols() end, desc = "LSP Symbols" },
      { "<leader>ls", function() FzfLua.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
      { "<leader>lx", function() FzfLua.lsp_document_diagnostics() end, desc = "LSP Workspace Symbols" },
      { "<leader>lX", function() FzfLua.lsp_workspace_diagnostics() end, desc = "LSP Workspace Symbols" },
      { "<leader>a", function() vim.lsp.buf.code_action() end, desc = "LSP: Code Action" },
      { "<C-k>", vim.lsp.buf.hover, desc = "LSP: Hover LSP Help" },
      { "<C-s>", vim.lsp.buf.signature_help, desc = "LSP Signature Help" },
      buffer = args.buf,
      noremap = true,
    }
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

---@type table<number, {token:lsp.ProgressToken, msg:string, done:boolean}[]>
local progress = vim.defaulttable()
vim.api.nvim_create_autocmd("LspProgress", {
  ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local value = ev.data.params.value --[[@as {percentage?: number, title?: string, message?: string, kind: "begin" | "report" | "end"}]]
    if not client or type(value) ~= "table" then return end
    local p = progress[client.id]

    for i = 1, #p + 1 do
      if i == #p + 1 or p[i].token == ev.data.params.token then
        p[i] = {
          token = ev.data.params.token,
          msg = ("[%3d%%] %s%s"):format(value.kind == "end" and 100 or value.percentage or 100, value.title or "", value.message and (" **%s**"):format(value.message) or ""),
          done = value.kind == "end",
        }
        break
      end
    end

    local msg = {} ---@type string[]
    progress[client.id] = vim.tbl_filter(function(v) return table.insert(msg, v.msg) or not v.done end, p)

    local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
    vim.notify(table.concat(msg, "\n"), "info", {
      id = "lsp_progress",
      title = client.name,
      opts = function(notif) notif.icon = #progress[client.id] == 0 and " " or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1] end,
    })
  end,
})
