return {
  {
    "neovim/nvim-lspconfig",
    event = "User FilePost",
    config = function()
      local lspconfig = require "lspconfig"
      local wk = require "which-key"
      wk.add {
        { "<leader>l", group = "LSP" },
        { "<leader>lx", vim.diagnostic.open_float, desc = "Open LSP Diagnostics" },
        { "<leader>lq", vim.diagnostic.open_float, desc = "Set LSP Loclist" },
        {
          "<leader>lf",
          function()
            require("conform").format { lsp_fallback = true }
          end,
          desc = "Format",
        },
      }

      -- export on_attach & capabilities
      local custom_on_attach = function(client, bufnr)
        vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        wk.add {
          { "<leader>lD", vim.lsp.buf.declaration, desc = "Goto declaration" },
          {
            "<leader>ld",
            function()
              require("fzf-lua").lsp_implementations()
            end,
            desc = "Goto implementation",
          },
          {
            "<leader>li",
            function()
              require("fzf-lua").lsp_definitions()
            end,
            desc = "Goto declaration",
          },
          { "<leader>lr", ":IncRename ", desc = "Rename" },
          {
            "<leader>lR",
            function()
              require("fzf-lua").lsp_references()
            end,
            desc = "References",
          },
          { "<leader>la", vim.lsp.buf.code_action, desc = "Code Action" },
          {
            "<leader>lS",
            function()
              require("fzf-lua").lsp_workspace_symbols()
            end,
            desc = "Workspace Symbols",
          },
          {
            "<leader>ls",
            function()
              require("fzf-lua").lsp_document_symbols()
            end,
            desc = "Document Symbols",
          },
          {
            "<leader>lt",
            function()
              require("fzf-lua").lsp_type_definitions()
            end,
            desc = "Type Definition",
          },
          {
            buffer = bufnr,
          },
        }

        wk.add {
          { "<C-K>", vim.lsp.buf.hover, desc = "Hover LSP Help" },
          { "<C-s>", vim.lsp.buf.signature_help, desc = "LSP Signature Help" },
          { buffer = bufnr },
        }
      end

      local servers = {
        "jqls",
        "neocmake",
        "marksman",
        "docker_compose_language_service",
        "dockerls",
        "jedi_language_server",
        "rust_analyzer",
        "bashls",
        "jsonls",
      }
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false
      capabilities.textDocument.completion.completionItem = {
        documentationFormat = { "markdown", "plaintext" },
        snippetSupport = true,
        preselectSupport = true,
        insertReplaceSupport = true,
        labelDetailsSupport = true,
        deprecatedSupport = true,
        commitCharactersSupport = true,
        tagSupport = { valueSet = { 1 } },
        resolveSupport = {
          properties = {
            "documentation",
            "detail",
            "additionalTextEdits",
          },
        },
      }

      vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

      for _, lsp in ipairs(servers) do
        lspconfig[lsp].setup {
          on_attach = custom_on_attach,
          capabilities = capabilities,
        }
      end

      require("lspconfig").lua_ls.setup {
        on_attach = custom_on_attach,
        capabilities = capabilities,

        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              library = {
                [vim.fn.expand "$VIMRUNTIME/lua"] = true,
                [vim.fn.expand "$VIMRUNTIME/lua/vim/lsp"] = true,
                [vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy"] = true,
              },
              maxPreload = 100000,
              preloadFileSize = 10000,
            },
          },
        },
      }

      require("lspconfig").clangd.setup {
        on_attach = custom_on_attach,
        capabilities = capabilities,

        root_dir = require("lspconfig").util.root_pattern(
          ".clangd",
          ".clang-tidy",
          ".clang-format",
          "compile_commands.json",
          "build/compile_commands.json",
          "compile_flags.txt",
          "configure.ac",
          ".git"
        ),
      }

      require("lspconfig").yamlls.setup {
        on_attach = custom_on_attach,
        capabilities = capabilities,

        settings = {
          yaml = {
            schemas = {
              ["https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json"] = ".gitlab-ci.yml",
            },
            customTags = {
              "!reference sequence",
            },
          },
        },
      }
    end,
  },
}
