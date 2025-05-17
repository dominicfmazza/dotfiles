local colortable = require("colors").colortable
return {
  {
    "nvim-lualine/lualine.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- Eviline config for lualine
      -- Author: shadmansaleh
      -- Credit: glepnir
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
          -- Disable sections and component separators
          component_separators = "",
          section_separators = "",
          theme = {
            -- We are going to use lualine_c an lualine_x as left and
            -- right section. Both are highlighted by c theme .  So we
            -- are just setting default looks o statusline
            normal = { c = { fg = colors.fg, bg = colors.bg } },
            inactive = { c = { fg = colors.fg, bg = colors.bg } },
          },
          globalstatus = true,
        },
        sections = {
          -- these are to remove the defaults
          lualine_a = {},
          lualine_b = {},
          lualine_y = {},
          lualine_z = {},
          -- These will be filled later
          lualine_c = {},
          lualine_x = {},
        },
        inactive_sections = {
          -- these are to remove the defaults
          lualine_a = {},
          lualine_b = {},
          lualine_y = {},
          lualine_z = {},
          lualine_c = {},
          lualine_x = {},
        },
      }

      -- Inserts a component in lualine_c at left section
      local function ins_left(component) table.insert(config.sections.lualine_c, component) end

      -- Inserts a component in lualine_x at right section
      local function ins_right(component) table.insert(config.sections.lualine_x, component) end

      ins_left {
        "mode",
        color = function()
          -- auto change color according to neovims mode
          local mode_color = {
            n = colors.red,
            i = colors.green,
            v = colors.blue,
            [""] = colors.blue,
            V = colors.blue,
            c = colors.magenta,
            no = colors.red,
            s = colors.orange,
            S = colors.orange,
            ic = colors.yellow,
            R = colors.violet,
            Rv = colors.violet,
            cv = colors.red,
            ce = colors.red,
            r = colors.cyan,
            rm = colors.cyan,
            ["r?"] = colors.cyan,
            ["!"] = colors.red,
            t = colors.red,
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

      -- Insert mid section. You can make any number of sections in neovim :)
      -- for lualine it's any number greater then 2
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
        color = { fg = colors.divider }, -- Sets highlighting of component
        padding = { left = 0, right = 0 }, -- We don't need space before this
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
        color = { fg = colors.bg }, -- Sets highlighting of component
        padding = { left = 1, right = 1 }, -- We don't need space before this
      }

      -- Now don't forget to initialize lualine
      lualine.setup(config)
    end,
  },
}
