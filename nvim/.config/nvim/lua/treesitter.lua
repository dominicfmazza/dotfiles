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
}

vim.api.nvim_create_autocmd('FileType', {
  pattern = { '<filetype>' },
  callback = function() 
      vim.treesitter.start() 
      vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()' 
      vim.wo[0][0].foldmethod = 'expr' 
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
