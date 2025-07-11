local autocmd = vim.api.nvim_create_autocmd

-- checks for gitlab-ci files
-- TODO: Could definitely be in a filetype configuration file
autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.{gitlab-ci,pipeline,ci}*.{yml,yaml}",
  callback = function()
    vim.bo.filetype = "yaml.gitlab"
  end,
})

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

