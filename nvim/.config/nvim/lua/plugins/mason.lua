return {
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonInstallAll", "MasonUpdate" },
    opts = {},
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("mason-tool-installer").setup {
        ensure_installed = {
          -- LSPs
          "dockerfile-language-server",
          "yaml-language-server",
          "basedpyright",
          "json-lsp",
          "bash-language-server",
          "marksman",
          "clangd",
          "lua-language-server",
          -- Formatters
          "prettierd",
          "beautysh",
          "stylua",
          "gersemi",
        },
      }
    end,
  },
  {},
}
