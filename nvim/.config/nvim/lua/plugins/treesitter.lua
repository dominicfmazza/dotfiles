return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "luadoc",
        "query",
        "help",
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
        use_languagetree = true,
      },
      indent = {
        enable = true,
      },
    },
  },
}
