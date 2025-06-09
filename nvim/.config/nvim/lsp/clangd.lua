return {
  cmd = {
    "clangd",
    "--clang-tidy",
    "--background-index",
    "-j=8",
    "--malloc-trim",
    "--pch-storage=memory",
    "--fallback-style=llvm",
  },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
  root_markers = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "build/compile_commands.json", "compile_flags.txt", "configure.ac", ".git" },
  capabilities = {
    textDocument = {
      completion = {
        editsNearCursor = true,
      },
    },
    offsetEncoding = { "utf-8", "utf-16" },
  },
}
