return {
  {
    "neovim/nvim-lspconfig",
    event = "User FilePost",
    dependencies = {
      -- main one
      { "ms-jpq/coq_nvim", branch = "coq" },

      -- 9000+ Snippets
      { "ms-jpq/coq.artifacts", branch = "artifacts" },

      -- lua & third party sources -- See https://github.com/ms-jpq/coq.thirdparty
      -- Need to **configure separately**
      { "ms-jpq/coq.thirdparty", branch = "3p" },
      -- - shell repl
      -- - nvim lua api
      -- - scientific calculator
      -- - comment banner
      -- - etc
    },
    init = function()
      vim.g.coq_settings = {
        auto_start = true,
        display = {
          mark_highlight_group = "DiffAdd",
          statusline = { helo = false },
        },
      }
    end,
    config = function()
      local lspconfig = require "lspconfig"
      local coq = require "coq" -- add this
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
          { "<leader>ld", require("telescope.builtin").lsp_implementations, desc = "Goto implementation" },
          { "<leader>li", require("telescope.builtin").lsp_definitions, desc = "Goto declaration" },
          -- {
          --   "<leader>lr",
          --   function()
          --     require "nvchad.lsp.renamer"()
          --   end,
          --   desc = "Rename",
          -- },
          { "<leader>lR", require("telescope.builtin").lsp_references, desc = "References" },
          { "<leader>la", vim.lsp.buf.code_action, desc = "Code Action" },
          { "<leader>lS", require("telescope.builtin").lsp_workspace_symbols, desc = "Workspace Symbols" },
          { "<leader>ls", require("telescope.builtin").lsp_document_symbols, desc = "Document Symbols" },
          { "<leader>lt", require("telescope.builtin").lsp_type_definitions, desc = "Type Definition" },
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
    "bashls",
        "ruff_lsp",
        "jsonls",
      }

      for _, lsp in ipairs(servers) do
        lspconfig[lsp].setup(coq.lsp_ensure_capabilities {
          on_attach = custom_on_attach,
        })
      end

      require("lspconfig").lua_ls.setup(coq.lsp_ensure_capabilities {
        on_attach = custom_on_attach,

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
      })

      require("lspconfig").clangd.setup(coq.lsp_ensure_capabilities {
        on_attach = custom_on_attach,

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
      })

      require("lspconfig").yamlls.setup(coq.lsp_ensure_capabilities {
        on_attach = custom_on_attach,

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
      })
    end,
  },
}
