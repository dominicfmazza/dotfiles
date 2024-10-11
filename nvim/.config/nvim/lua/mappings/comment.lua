local wk = require("which-key")

wk.add({
  {
    "<leader>/",
    function()
      require("Comment.api").toggle.linewise.count(vim.v.count > 0 and vim.v.count or 1)
    end,
    desc = "Toggle linewise comment",
    mode = "n"
  }
})


wk.add({
  {
    "<leader>/",
    "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>",
    desc = "Toggle block comment",
    mode = "v"
  }
})
