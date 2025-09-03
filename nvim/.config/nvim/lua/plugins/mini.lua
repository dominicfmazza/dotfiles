return {
  "echasnovski/mini.nvim",
  version = "*",
  lazy = false,
  config = function()
    require("mini.icons").setup()
    require("mini.icons").tweak_lsp_kind()

    require("mini.colors").setup()

    vim.api.nvim_create_user_command(
      "ColorEdit",
      function()
        MiniColors.interactive {
          mappings = {
            Apply = "<leader>ca",
            Reset = "<leader>cr",
            Quit = "<leader>cq",
            Write = "<leader>cw",
          },
        }
      end,
      { desc = "MiniColors interactive with custom keybinds" }
    )

    require("mini.ai").setup()
    require("mini.align").setup()
    require("mini.hipatterns").setup {
      highlighters = {
        -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
        fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
        hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
        todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
        note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },

        -- Highlight hex color strings (`#rrggbb`) using that color
        hex_color = require("mini.hipatterns").gen_highlighter.hex_color(),
      },
    }
    require("mini.extra").setup()

    require("mini.statusline").setup()

    require("mini.jump").setup {
      delay = { highlight = 1e7 },
    }
    require("mini.notify").setup()

    local set_keymap = function(lhs, rhs, mode) vim.keymap.set(mode or "n", lhs, rhs, { noremap = true }) end
    require("mini.files").setup {
      mappings = {
        go_in = "l",
        go_in_plus = "<CR>",
        reset = "",
      },
      options = {
        permanent_delete = false, 
      }
    }
    set_keymap("<leader>e", function()
      if not MiniFiles.close() then MiniFiles.open(nil, false) end
    end)

    local set_cwd = function()
      local path = (MiniFiles.get_fs_entry() or {}).path
      if path == nil then return vim.notify "Cursor is not on valid entry" end
      if vim.fn.isdirectory(path) == true then
        vim.fn.chdir(path)
      else
        vim.fn.chdir(vim.fs.dirname(path))
      end
      MiniFiles.open(nil, false)
    end

    local go_up = function()
      local path = vim.fn.getcwd()
      vim.fn.chdir(vim.fs.dirname(path))
      MiniFiles.open(nil, false)
    end

    local yank_path = function()
      local path = (MiniFiles.get_fs_entry() or {}).path
      if path == nil then return vim.notify "Cursor is not on valid entry" end
      vim.fn.setreg(vim.v.register, path)
    end

    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniFilesBufferCreate",
      callback = function(args)
        local b = args.data.buf_id
        vim.keymap.set("n", ".", set_cwd, { noremap = true, buffer = b, desc = "Set cwd" })
        vim.keymap.set("n", "gy", yank_path, { buffer = b, desc = "Yank path" })
        vim.keymap.set("n", "<BS>", go_up, { buffer = b, desc = "Yank path" })
      end,
    })

    local colortable = {
      rosewater = "#ffd7d9",
      flamingo = "#ffb3b8",
      pink = "#ff9cac",
      mauve = "#c792ea",
      red = "#f07178",
      maroon = "#dc6068",
      peach = "#f78c6c",
      yellow = "#ffcb6b",
      green = "#c3e88d",
      teal = "#89ddff",
      sky = "#b0c9ff",
      sapphire = "#82aaff",
      blue = "#6e98eb",
      lavender = "#b480d6",
      text = "#f4f4f4",
      subtext1 = "#dfdfdf",
      subtext0 = "#cacaca",
      overlay2 = "#b6b6b6",
      overlay1 = "#a1a1a1",
      overlay0 = "#8c8c8c",
      surface2 = "#777777",
      surface1 = "#626262",
      surface0 = "#4d4d4d",
      mantle = "#242424",
      base = "#0f0f0f",
      crust = "#393939",
    }
    require("mini.snippets").setup()

    require("mini.completion").setup()

    require("mini.base16").setup {
      palette = {
        base00 = colortable.base,
        base01 = colortable.base,
        base02 = colortable.surface0,
        base03 = colortable.surface1,
        base04 = colortable.surface2,
        base05 = colortable.text,
        base06 = colortable.rosewater,
        base07 = colortable.lavender,
        base08 = colortable.pink,
        base09 = colortable.peach,
        base0A = colortable.yellow,
        base0B = colortable.green,
        base0C = colortable.teal,
        base0D = colortable.blue,
        base0E = colortable.mauve,
        base0F = colortable.flamingo,
      },
      use_cterm = true,
    }
  end,
}
