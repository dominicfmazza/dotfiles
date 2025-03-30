local function switch_source_handler(_err, uri)
  if not uri or uri == "" then
    vim.api.nvim_echo({ { "Corresponding file cannot be determined" } }, false, {})
    return
  end
  local file_name = vim.uri_to_fname(uri)
  vim.api.nvim_cmd({
    cmd = "edit",
    args = { file_name },
  }, {})
end

local function symbol_info_handler(err, result)
  if err or (#result == 0) then return end
  local name_str = string.format("name: %s", result[1].name)
  local container_str = string.format("container: %s", result[1].containerName)
  vim.lsp.util.open_floating_preview({ name_str, container_str }, "", {
    height = 2,
    width = math.max(string.len(name_str), string.len(container_str)),
    focusable = false,
    focus = false,
  })
end

return {
  cmd = {
    "clangd",
    "--clang-tidy",
    "--background-index",
    "--fallback-style=llvm",
  },
  filetypes = { "c", "cpp", "h", "hpp" },
  root_markers = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "build/compile_commands.json", "compile_flags.txt", "configure.ac", ".git" },
  commands = {
    ClangdSwitchSourceHeader = {
      function()
        vim.lsp.buf_request(0, "textDocument/switchSourceHeader", {
          uri = vim.uri_from_bufnr(0),
        }, switch_source_handler)
      end,
    },
    ClangdSymbolInfo = {
      vim.lsp.buf_request(0, "textDocument/symbolInfo", {
        textDocument = {
          uri = vim.uri_from_bufnr(0),
        },
        position = {
          line = vim.fn.getcurpos()[2] - 1,
          character = vim.fn.getcurpos()[3] - 1,
        },
      }, symbol_info_handler),
    },
  },
}
