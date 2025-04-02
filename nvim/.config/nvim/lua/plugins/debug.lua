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
      local wk = require "which-key"
      wk.add {
        { "<leader>d", group = "+debugger" },
        { "<leader>dc", function() require("dap").continue() end, desc = "DAP: Continue" },
        { "<leader>do", function() require("dap").step_over() end, desc = "DAP: Step Over" },
        { "<leader>di", function() require("dap").step_into() end, desc = "DAP: Step Into" },
        { "<leader>du", function() require("dap").step_out() end, desc = "DAP: Step Out" },
        { "<Leader>db", function() require("dap").toggle_breakpoint() end, desc = "DAP: Toggle Breakpoint" },
        { "<Leader>dB", function() require("dap").set_breakpoint() end, desc = "DAP: Set Breakpoint" },
        { "<Leader>dl", function() require("dap").set_breakpoint(nil, nil, vim.fn.input "Log point message: ") end, desc = "DAP: Log Point" },
        { "<Leader>dr", function() require("dap").repl.open() end, desc = "DAP: Repl" },
        { "<Leader>dl", function() require("dap").run_last() end, desc = "DAP: Run Last" },
      }
    end,
  },
}
