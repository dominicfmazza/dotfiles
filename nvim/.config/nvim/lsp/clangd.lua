return {
  cmd = {
    "clangd",
    "--background-index=true",
    "--pch-storage=memory",
    "--malloc-trim",
    "-j=24",
  },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
  root_markers = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "build/compile_commands.json", "compile_flags.txt", "configure.ac", ".git" },
  -- capabilities = {
  --   textDocument = {
  --     completion = {
  --       editsNearCursor = true,
  --     },
  --   },
  --   offsetEncoding = { "utf-8", "utf-16" },
  -- },
}
