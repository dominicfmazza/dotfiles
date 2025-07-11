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
          markdown = { "mdformat" },
          json = { "jq" },
          yaml = { "yamlfmt" },
          rust = {"rustfmt"},
        },
      }
      require("conform").setup(options)
    end,
  },
}
