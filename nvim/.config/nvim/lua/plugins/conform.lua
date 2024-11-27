return {
  {
    "stevearc/conform.nvim",
    config = function()
      local options = {
        formatters_by_ft = {
          lua = { "stylua" },
          cpp = { "clang_format" },
          cmake = { "gersemi" },
          python = { "black" },
          bash = { "beautysh" },
          markdown = { "prettierd" },
          json = { "prettierd" },
          yaml = { "prettierd" },
          javascript = { "prettierd" },
          typescript = { "prettierd" },
          rust = {"rustfmt"},
          vue = { "prettierd" },
          xml = { "prettierd" },
        },
      }

      require("conform").setup(options)
    end,
  },
}
