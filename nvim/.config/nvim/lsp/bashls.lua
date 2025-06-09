return {
  cmd = { "bash-language-server", "start" },
  settings = {
    globPattern = vim.env.GLOB_PATTERN or "*@(.sh|.inc|.bash|.command)",
  },
  filetypes = { "bash", "sh" },
  root_markers = function(fname) return vim.fs.dirname(vim.fs.find(".git", { path = fname, upward = true })[1]) end,
  single_file_support = true,
}
