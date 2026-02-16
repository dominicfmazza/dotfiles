vim.pack.add { "https://github.com/mrcjkb/rustaceanvim.git" }

vim.g.rustaceanvim = {}

local bufnr = vim.api.nvim_get_current_buf()
vim.keymap.set("n", "<leader>a", function()
  vim.cmd.RustLsp "codeAction" -- supports rust-analyzer's grouping
end, { silent = true, buffer = bufnr })
vim.keymap.set(
  "n",
  "K", -- Override Neovim's built-in hover keymap with rustaceanvim's hover actions
  function() vim.cmd.RustLsp { "hover", "actions" } end,
  { silent = true, buffer = bufnr }
)
