return {
  {
    "linux-cultist/venv-selector.nvim",
    opts = {
      -- Your options go here
      -- name = "venv",
      -- auto_refresh = false
    },
    lazy=false,
    branch="regexp",
    keys = {
      -- Keymap to open VenvSelector to pick a venv.
      { "<leader>vs", "<cmd>VenvSelect<cr>" },
    },
  },
}
