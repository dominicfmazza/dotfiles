return {
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonInstallAll", "MasonUpdate" },
    opts = {
      pip = {
        install_args = { "--default-timeout", "1000" },
      },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    lazy = false,
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
}
