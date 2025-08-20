return {
    'echasnovski/mini.nvim', 
    version = "*",
    lazy = false,
    config = function()
        require("mini.ai").setup()
        require("mini.align").setup()
    end
}
