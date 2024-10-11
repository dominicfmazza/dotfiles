return {
  {
    "williamboman/mason.nvim",
        cmd = { "Mason", "MasonInstall", "MasonInstallAll", "MasonUpdate" },
        opts = {}
  },
  {
    "jay-babu/mason-null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "nvimtools/none-ls.nvim",
    },
    config = function()
      require("mason-null-ls").setup {
        ensure_installed = {
          -- lua
          "lua-language-server", -- lsp
          "stylua", -- formatter
          -- cmake
          "neocmakelsp", -- lsp
          "gersemi", -- formatter
          -- c++/cuda/c
          "clangd", -- lsp
          -- markdown
          "marksman", -- markdown
          -- bash
          "bash-language-server", -- lsp
          "beautysh", -- formatter
          -- json
          "json-lsp", -- lsp
          -- python
          "jedi-language-server",
          "black", -- lsp
          -- yaml
          "yaml-language-server", -- lsp
          -- docker
          "dockerfile-language-server", --lsp
          -- json/markdown/yaml
          "prettierd", -- formatter
          -- cmake
          "gersemi",
          -- bash
          "beautysh",
        },
      }
    end,
  },
}
