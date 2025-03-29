return {
  cmd = {
    "clangd",
    "--clang-tidy",
    "--background-index",
    "--fallback-style=llvm",
  },
  filetypes = { "c", "cpp", "h", "hpp" },
  root_markers = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "build/compile_commands.json", "compile_flags.txt", "configure.ac", ".git" },
}
