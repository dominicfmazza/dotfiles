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
          "dockerfile-language-server", --lsp
          "yaml-language-server", -- lsp
          "basedpyright",
          "json-lsp", -- lsp
          "bash-language-server", -- lsp
          "marksman", -- markdown
          "clangd", -- lsp
          "lua-language-server", -- lsp
          -- Formatters
          "prettierd", -- formatter
          "beautysh",
          "stylua", -- formatter
          "gersemi", -- formatter
        },
      }
    end,
  },
  {},
}
