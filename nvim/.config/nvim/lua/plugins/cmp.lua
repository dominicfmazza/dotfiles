return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    {
      -- snippet plugin
      "L3MON4D3/LuaSnip",
      dependencies = "rafamadriz/friendly-snippets",
      opts = { history = true, updateevents = "TextChanged,TextChangedI" },
      config = function(_, opts)
        require("luasnip").config.set_config(opts)
        -- vscode format
        require("luasnip.loaders.from_vscode").lazy_load { exclude = vim.g.vscode_snippets_exclude or {} }
        require("luasnip.loaders.from_vscode").lazy_load { paths = vim.g.vscode_snippets_path or "" }

        -- snipmate format
        require("luasnip.loaders.from_snipmate").load()
        require("luasnip.loaders.from_snipmate").lazy_load { paths = vim.g.snipmate_snippets_path or "" }

        -- lua format
        require("luasnip.loaders.from_lua").load()
        require("luasnip.loaders.from_lua").lazy_load { paths = vim.g.lua_snippets_path or "" }

        vim.api.nvim_create_autocmd("InsertLeave", {
          callback = function()
            if
              require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
              and not require("luasnip").session.jump_active
            then
              require("luasnip").unlink_current()
            end
          end,
        })
      end,
    },
    {
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lua",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp-document-symbol",
      "hrsh7th/cmp-nvim-lsp-signature-help",
      "delphinus/cmp-ctags",
      "hrsh7th/cmp-cmdline",
    },
  },
  config = function()
    local cmp = require "cmp"
    local types = require "cmp.types"
    local compare = require "cmp.config.compare"
    local luasnip = require "luasnip"
    local str = require "cmp.utils.str"

    ---@type table<integer, integer>
    local modified_priority = {
      [types.lsp.CompletionItemKind.Variable] = types.lsp.CompletionItemKind.Method,
      [types.lsp.CompletionItemKind.Snippet] = 0, -- top
      [types.lsp.CompletionItemKind.Keyword] = 0, -- top
      [types.lsp.CompletionItemKind.Text] = 100, -- bottom
    }
    ---@param kind integer: kind of completion entry
    local function modified_kind(kind)
      return modified_priority[kind] or kind
    end

    local buffers = {
      name = "buffer",
      option = {
        keyword_length = 3,
        get_bufnrs = function() -- from all buffers (less than 1MB)
          local bufs = {}
          for _, bufn in ipairs(vim.api.nvim_list_bufs()) do
            local buf_size = vim.api.nvim_buf_get_offset(bufn, vim.api.nvim_buf_line_count(bufn))
            if buf_size < 1024 * 1024 then
              table.insert(bufs, bufn)
            end
          end
          return bufs
        end,
      },
    }

    cmp.setup.cmdline({ "/", "?" }, {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({ { name = "nvim_lsp_document_symbol" } }, {
        { name = "buffer" },
      }),
    })

    cmp.setup.cmdline(":", {
      sources = cmp.config.sources {
        { name = "cmdline" },
      },
    })

    require("cmp").setup {
      completion = { completeopt = "menu,menuone" },

      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      },

      mapping = {
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-d>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.close(),

        ["<CR>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            if luasnip.expandable() then
              luasnip.expand()
            else
              cmp.confirm {
                select = true,
              }
            end
          else
            fallback()
          end
        end),

        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.locally_jumpable(1) then
            luasnip.jump(1)
          else
            fallback()
          end
        end, { "i", "s" }),

        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.locally_jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      },

      sources = {
        { name = "nvim_lsp" },
        { name = "luasnip" },
        { name = "nvim_lsp_signature_help" },
        { name = "nvim_lua" },
        { name = "path" },
        {
          name = "ctags",
          option = {
            executable = "ctags",
            trigger_characters = { "." },
            trigger_characters_ft = {},
          },
        },
        buffers,
      },
      sorting = {
        -- TODO: Would be cool to add stuff like "See variable names before method names" in rust, or something like that.
        comparators = {
          cmp.config.compare.locality,
          cmp.config.compare.recently_used,
          cmp.config.compare.score,
          cmp.config.compare.offset,
          cmp.config.compare.order,
          -- copied from cmp-under, but I don't think I need the plugin for this.
          -- I might add some more of my own.
          function(entry1, entry2)
            local _, entry1_under = entry1.completion_item.label:find "^_+"
            local _, entry2_under = entry2.completion_item.label:find "^_+"
            entry1_under = entry1_under or 0
            entry2_under = entry2_under or 0
            if entry1_under > entry2_under then
              return false
            elseif entry1_under < entry2_under then
              return true
            end
          end,
        },
      },
    }
  end,
}
