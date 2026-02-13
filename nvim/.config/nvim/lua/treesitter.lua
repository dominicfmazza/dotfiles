require("nvim-treesitter").setup{
    install_dir = vim.fn.stdpath('data') .. '/site'
}

require("nvim-treesitter").install {
    'rust',
    'zsh',
    'bash',
    'cpp',
    'cuda',
    'c',
    'yaml',
    'dockerfile',
    'markdown',
    'lua',
    'cmake',
    'vimdoc',
}


vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('tree-sitter-enable', { clear = true }),
    callback = function(args)
      local lang = vim.treesitter.language.get_lang(args.match)
      if not lang then return end

      if vim.treesitter.query.get(lang, 'highlights') then vim.treesitter.start(args.buf) end

      if vim.treesitter.query.get(lang, 'indents') then
        vim.opt_local.indentexpr = 'v:lua.require("nvim-treesitter").indentexpr()'
      end

      if vim.treesitter.query.get(lang, 'folds') then
        vim.opt_local.foldmethod = 'expr'
        vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        vim.opt_local.foldlevel = 999
      end
    end,
})
