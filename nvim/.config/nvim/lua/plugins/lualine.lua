local colortable = require("colors").colortable
return {
  {
    "nvim-lualine/lualine.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local lualine = require "lualine"

      local colors = {
        bg = colortable.mantle,
        fg = colortable.subtext0,
        yellow = colortable.yellow,
        cyan = colortable.teal,
        darkblue = colortable.sapphire,
        green = colortable.green,
        orange = colortable.flamingo,
        violet = colortable.lavender,
        magenta = colortable.mauve,
        blue = colortable.blue,
        red = colortable.red,
        divider = colortable.surface2,
      }

      local conditions = {
        buffer_not_empty = function() return vim.fn.empty(vim.fn.expand "%:t") ~= 1 end,
        hide_in_width = function() return vim.fn.winwidth(0) > 80 end,
        check_git_workspace = function()
          local filepath = vim.fn.expand "%:p:h"
          local gitdir = vim.fn.finddir(".git", filepath .. ";")
          return gitdir and #gitdir > 0 and #gitdir < #filepath
        end,
      }

      -- Config
      local config = {
        options = {
          component_separators = "",
          section_separators = "",
          theme = {
            normal = { c = { fg = colors.fg, bg = colors.bg } },
            inactive = { c = { fg = colors.fg, bg = colors.bg } },
          },
          globalstatus = true,
        },
        sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_y = {},
          lualine_z = {},
          lualine_c = {},
          lualine_x = {},
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_y = {},
          lualine_z = {},
          lualine_c = {},
          lualine_x = {},
        },
      }

      local function ins_left(component) table.insert(config.sections.lualine_c, component) end

      local function ins_right(component) table.insert(config.sections.lualine_x, component) end

      ins_left {
        "mode",
        color = function()
          local mode_color = {
            n = colors.blue,
            i = colors.green,
            v = colors.red,
            [""] = colors.red,
            V = colors.red,
            c = colors.magenta,
            no = colors.blue,
            s = colors.orange,
            S = colors.orange,
            ic = colors.yellow,
            R = colors.violet,
            Rv = colors.violet,
            cv = colors.blue,
            ce = colors.blue,
            r = colors.cyan,
            rm = colors.cyan,
            ["r?"] = colors.cyan,
            ["!"] = colors.blue,
            t = colors.blue,
          }
          return { gui = "bold", fg = colors.bg, bg = mode_color[vim.fn.mode()] }
        end,
        padding = { left = 1, right = 1 },
      }

      ins_left {
        "filename",
        cond = conditions.buffer_not_empty,
        color = { fg = colors.fg, gui = "bold" },
      }

      ins_left {
        "diagnostics",
        sources = { "nvim_diagnostic" },
        symbols = { error = " ", warn = " ", info = " " },
        diagnostics_color = {
          error = { fg = colors.red },
          warn = { fg = colors.yellow },
          info = { fg = colors.cyan },
        },
      }

      ins_left {
        function() return "%=" end,
      }

      ins_left {
        "branch",
        icon = "",
        color = { fg = colors.fg, gui = "bold" },
      }

      ins_left {
        "diff",
        symbols = { added = " ", modified = "󰝤 ", removed = " " },
        diff_color = {
          added = { fg = colors.green },
          modified = { fg = colors.orange },
          removed = { fg = colors.red },
        },
        cond = conditions.hide_in_width,
      }

      ins_right {
        function()
          local msg = "No Active Lsp"
          local buf_ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
          local clients = vim.lsp.get_clients()
          if next(clients) == nil then return msg end
          for _, client in ipairs(clients) do
            local filetypes = client.config.filetypes
            if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then return client.name end
          end
          return msg
        end,
        icon = " ",
        color = { fg = colors.fg, gui = "bold" },
      }

      ins_right {
        "overseer",
      }

      ins_right {
        function() return "▊" end,
        color = { fg = colors.divider },
        padding = { left = 0, right = 0 }, 
      }

      ins_right {
        -- filesize component
        "filesize",
        cond = conditions.buffer_not_empty,
      }

      ins_right { "location" }

      ins_right { "progress", color = { fg = colors.fg, guifg = "bold" } }

      ins_right {
        function() return "▊" end,
        color = { fg = colors.bg }, 
        padding = { left = 1, right = 1 }, 
      }

      lualine.setup(config)
    end,
  },
}
