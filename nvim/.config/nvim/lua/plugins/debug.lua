return {
  {
    "mfussenegger/nvim-dap",
    lazy = false,
    dependencies = {
      {
        "igorlfs/nvim-dap-view",
        config = function()
          vim.keymap.set("n", "<leader>dv", function() require("dap-view").toggle() end, { desc = "Toggle nvim-dap-view" })
        end,
      },
      ...,
    },
    config = function()
      local dap = require "dap"
      dap.adapters.gdb = {
        type = "executable",
        command = "gdb",
        args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
      }
    end,
  },
}
