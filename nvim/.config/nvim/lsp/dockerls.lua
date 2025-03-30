return {
  cmd = { "docker-langserver", "--stdio" },
  filetypes = { "dockerfile" },
  root_dir = function(fname) return vim.fs.dirname(vim.fs.find("Dockerfile", { path = fname, upward = true })[1]) end,
  single_file_support = true,
}
