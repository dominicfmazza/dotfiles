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
          function() require("conform").format { lsp_fallback = true } end,
          desc = "Format",
        },
      }

      -- export on_attach & capabilities
      local custom_on_attach = function(client, bufnr)
        vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        wk.add {
          { "<leader>lr", ":IncRename ", desc = "Rename" },
          -- LSP
          { "<leader>ld", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
          { "<leader>lD", function() Snacks.picker.lsp_declarations() end, desc = "Goto Declaration" },
          { "<leader>lR", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
          { "<leader>li", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
          { "<leader>lt", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
          { "<leader>ls", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
          { "<leader>lS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
          { "<leader>la", vim.lsp.buf.code_action, desc = "Code Action" },
          {
            buffer = bufnr,
          },
        }

        wk.add {
          { "<C-K>", vim.lsp.buf.hover, desc = "Hover LSP Help" },
          { "<C-s>", vim.lsp.buf.signature_help, desc = "LSP Signature Help" },
          { buffer = bufnr },
        }

        local handler = function(virtText, lnum, endLnum, width, truncate)
          local newVirtText = {}
          local suffix = (" 󰁂 %d "):format(endLnum - lnum)
          local sufWidth = vim.fn.strdisplaywidth(suffix)
          local targetWidth = width - sufWidth
          local curWidth = 0
          for _, chunk in ipairs(virtText) do
            local chunkText = chunk[1]
            local chunkWidth = vim.fn.strdisplaywidth(chunkText)
            if targetWidth > curWidth + chunkWidth then
              table.insert(newVirtText, chunk)
            else
              chunkText = truncate(chunkText, targetWidth - curWidth)
              local hlGroup = chunk[2]
              table.insert(newVirtText, { chunkText, hlGroup })
              chunkWidth = vim.fn.strdisplaywidth(chunkText)
              -- str width returned from truncate() may less than 2nd argument, need padding
              if curWidth + chunkWidth < targetWidth then suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth) end
              break
            end
            curWidth = curWidth + chunkWidth
          end
          table.insert(newVirtText, { suffix, "MoreMsg" })
          return newVirtText
        end

        require("ufo").setFoldVirtTextHandler(bufnr, handler)
      end

      local servers = {
        "jqls",
        "neocmake",
        "marksman",
        "docker_compose_language_service",
        "dockerls",
        "rust_analyzer",
        "glsl_analyzer",
        "bashls",
        "jsonls",
        "gitlab_ci_ls",
        "basedpyright",
        "yamlls",
      }
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false
      capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      }
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

        root_dir = require("lspconfig").util.root_pattern(".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "build/compile_commands.json", "compile_flags.txt", "configure.ac", ".git"),
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
