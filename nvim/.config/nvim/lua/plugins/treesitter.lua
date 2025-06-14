return {
  {
    priority = 902,
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate",

    config = function()
      require("nvim-treesitter.configs").setup {
        ensure_installed = {
          "vim",
          "lua",
          "vimdoc",
          "luadoc",
          "query",
          "cpp",
          "cuda",
          "c",
          "cmake",
          "yaml",
          "python",
          "markdown",
          "markdown_inline",
          "bash",
          "regex",
        },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
      }
    end,
  },
}
