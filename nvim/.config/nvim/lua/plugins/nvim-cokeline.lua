return {
  "willothy/nvim-cokeline",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for v0.4.0+
    "nvim-tree/nvim-web-devicons", -- If you want devicons
  },
  config = function()
    local is_picking_focus = require("cokeline.mappings").is_picking_focus
    local is_picking_close = require("cokeline.mappings").is_picking_close
    local get_hex = require("cokeline.hlgroups").get_hl_attr

    local red = vim.g.terminal_color_1
    local yellow = vim.g.terminal_color_3

    require("cokeline").setup {
      default_hl = {
        fg = function(buffer)
          return buffer.is_focused and get_hex("Normal", "fg") or get_hex("Comment", "bg")
        end,
        bg = function(buffer)
          return buffer.is_focused and get_hex("Normal", "bg") or get_hex("NormalFloat", "bg")
        end,
      },
      sidebar = {
        filetype = { "NvimTree", "neo-tree" },
        components = {
          {
            text = "Files",
            fg = yellow,
            bg = function()
              return get_hex("NvimTreeNormal", "bg")
            end,
            bold = true,
          },
        },
      },
      components = {
        {
          text = function(buffer)
            return (buffer.index ~= 1) and "▏" or ""
          end,
        },
        {
          text = "  ",
        },
        {
          text = function(buffer)
            return (is_picking_focus() or is_picking_close()) and buffer.pick_letter .. " " or buffer.devicon.icon
          end,
          fg = function(buffer)
            return (is_picking_focus() and yellow) or (is_picking_close() and red) or buffer.devicon.color
          end,
          italic = function()
            return (is_picking_focus() or is_picking_close())
          end,
          bold = function()
            return (is_picking_focus() or is_picking_close())
          end,
        },
        {
          text = " ",
        },
        {
          text = function(buffer)
            return buffer.unique_prefix .. buffer.filename .. "  "
          end,
          bold = function(buffer)
            return buffer.is_focused
          end,
          italic = function(buffer)
            return buffer.is_modified
          end,
        },
        {
          text = "󰅖",
          on_click = function(_, _, _, _, buffer)
            buffer:delete()
          end,
        },
        {
          text = "  ",
        },
      },
    }

    local wk = require "which-key"

    wk.add {
      { "<leader>b", group = "Bufferline" },
      {
        "<leader>bb",
        function()
          require("cokeline.mappings").pick "focus"
        end,
        desc = "Pick Buffer to focus",
      },
      {
        "<leader>bq",
        "<cmd>silent! w <bar> %bd <bar> e# <bar> bd# <CR>",
        desc = "Close all buffers but current",
        silent = true,
      },
      {
        "<leader>bc",
        function()
          require("cokeline.mappings").pick "close"
        end,
        desc = "Pick Buffer to close",
      },
      {
        "<leader>bd",
        function()
          require("cokeline.utils").buf_delete(vim.fn.bufnr "%")
          vim.cmd.redrawtabline()
        end,
        desc = "Delete current Buffer",
      },
      noremap = true,
    }
  end,
}
