local highlight = vim.api.nvim_set_hl

highlight(0, "MiniPickBorder", { link = "Title" })
highlight(0, "MiniPickBorderBusy", { link = "Title" })
highlight(0, "MiniPickBorderText", { link = "Title" })
highlight(0, "MiniPickIconDirectory", { link = "Title" })
highlight(0, "MiniPickIconFile", { link = "Title" })
highlight(0, "MiniPickNormal", { link = "Normal" })
highlight(0, "MiniPickHeader", { link = "Title" })
highlight(0, "MiniPickMatchCurrent", { link = "PmenuSel" })
highlight(0, "MiniPickMatchMarked", { link = "FloatTitle" })
highlight(0, "MiniPickMatchRanges", { link = "FloatTitle" })
highlight(0, "MiniPickPreviewLine", { link = "CursorLine" })
highlight(0, "MiniPickPreviewRegion", { link = "PmenuThumb" })
highlight(0, "MiniPickPrompt", { link = "Title" })
highlight(0, "MiniPickCursor", { link = "CursorLine" })

local set_keymap = function(lhs, rhs, mode) vim.keymap.set(mode or "n", lhs, rhs, { noremap = true }) end

local short_path = function(path) return vim.startswith(path, cwd) and path:sub(cwd:len() + 1) or vim.fn.fnamemodify(path, ":~") end

local load_temp_rg = function(f)
  local rg_env = "RIPGREP_CONFIG_PATH"
  local cached_rg_config = vim.uv.os_getenv(rg_env) or ""
  vim.uv.os_setenv(rg_env, vim.fn.stdpath "config" .. "/.rg")
  f()
  vim.uv.os_setenv(rg_env, cached_rg_config)
end

local pickers = {
  greppier = function()
    local pick = require "mini.pick"
    load_temp_rg(function() pick.builtin.grep_live { tool = "rg" } end)
  end,
  ffiles = function() 
    local pick = require "mini.pick"
    load_temp_rg(function() pick.builtin.files{ tool = "rg" } end)
  end,
  registry = function()
    local picker = require "mini.pick"
    local selected = picker.start {
      source = { items = vim.tbl_keys(picker.registry), name = "Registry" },
    }

    if selected == nil then return end

    return picker.registry[selected]()
  end,
  git_status = function()
    local selection = require("mini.pick").builtin.cli({
      command = {
        "git",
        "status",
        "-s",
      },
    }, {
      source = {
        name = "Git Status",
        preview = function(bufnr, item)
          local file = vim.trim(item):match "%s+(.+)"
          -- get diff and show
          local append_data = function(_, data)
            if data then
              vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, data)
              vim.api.nvim_buf_set_option(bufnr, "filetype", "diff")
            end
          end

          vim.fn.jobstart({ "git", "diff", "HEAD", file }, {
            stdout_buffered = true,
            on_stdout = append_data,
            on_stderr = append_data,
            vim.api.nvim_buf_set_option(bufnr, "modifiable", false),
          })
        end,
      },
    })

    if selection then vim.cmd.edit(vim.trim(selection):match "%s+(.+)") end
  end,
  find = function()
    local register = vim.fn.getreg '"'
    local cursor = vim.api.nvim_win_get_cursor(0)
    local view = vim.fn.winsaveview()

    vim.cmd [[normal! "xy]]

    local selection = vim.fn.getreg '"'

    vim.fn.setreg('"', register)
    vim.fn.winrestview(view)
    vim.api.nvim_win_set_cursor(0, cursor)

    require("mini.pick").builtin.grep({ pattern = selection }, { source = { name = string.format('Grep "%s"', selection) } })
  end,
  quickfix = function()
    require("mini.pick").start {
      source = {
        items = vim.fn.getqflist(),
        name = "Quickfix List",
      },
    }
  end,
  loclist = function()
    require("mini.pick").start {
      source = {
        items = vim.fn.getloclist(0),
        name = "Location List",
      },
    }
  end,
  oldfiles = function()
    local items = {}
    local cwd = vim.fn.getcwd()
    -- Ensure cwd has a trailing slash
    cwd = cwd:sub(-1) == "/" and cwd or (cwd .. "/")

    for _, path in ipairs(vim.v.oldfiles) do
      local normal_path = nil
      if vim.startswith(path, cwd) then
        -- Use ./ as cwd prefix
        normal_path = "." .. path:sub(cwd:len())
      else
        -- Use ~ as home directory prefix
        normal_path = vim.fn.fnamemodify(path, ":~")
      end

      table.insert(items, normal_path)
    end

    local selection = require("mini.pick").start {
      source = {
        items = items,
        name = "Recent Files",
      },
    }

    if selection then vim.cmd.edit(vim.trim(selection):match "%s+(.+)") end
  end,
}

local picker = require "mini.pick"

-- Add custom pickers to registry
pickers = vim.tbl_extend("force", pickers, picker.builtin)
picker.registry = pickers

-- Bind keys enabling quick access to pickers
set_keymap("<F1>", pickers.help)
set_keymap(",o", pickers.oldfiles)
set_keymap("<leader>,", pickers.resume)
set_keymap("<leader>ff", pickers.ffiles)
set_keymap("<leader>fb", pickers.buffers)
set_keymap("<leader>fg", pickers.greppier)
set_keymap("<leader>fw", pickers.find, "v")
set_keymap("<leader>gs", pickers.git_status)
set_keymap("<leader>fp", pickers.registry)
set_keymap("<leader>fq", pickers.quickfix)
set_keymap("<leader>fl", pickers.loclist)

require("mini.pick").setup {
  delay = {
    async = 10,
    busy = 30,
  },

  mappings = {
    caret_left = "<Left>",
    caret_right = "<Right>",

    choose = "<CR>",
    choose_in_split = "<C-s>",
    choose_in_tabpage = "<C-t>",
    choose_in_vsplit = "<C-v>",
    choose_marked = "<C-CR>",

    delete_char = "<BS>",
    delete_char_right = "<S-BS>",
    delete_left = "<A-BS>",
    delete_word = "<C-w>",

    mark = "<C-x>",
    mark_all = "<C-a>",

    move_start = "<C-g>",
    move_down = "<C-j>",
    move_up = "<C-k>",

    paste = "<A-p>",

    refine = "<C-Space>",
    refine_marked = "<M-Space>",

    scroll_up = "<C-u>",
    scroll_down = "<C-d>",
    scroll_left = "<C-h>",
    scroll_right = "<C-l>",

    stop = "<Esc>",

    toggle_info = "<S-Tab>",
    toggle_preview = "<Tab>",

    send_to_qflist = {
      char = "<C-q>",
      func = function()
        local list = {}
        local matches = picker.get_picker_matches().all

        for _, match in ipairs(matches) do
          if type(match) == "table" then
            table.insert(list, match)
          else
            local path, lnum, col, search = string.match(match, "(.-)%z(%d+)%z(%d+)%z%s*(.+)")
            local text = path and string.format("%s [%s:%s]  %s", path, lnum, col, search)
            local filename = path or vim.trim(match):match "%s+(.+)"

            table.insert(list, {
              filename = filename or match,
              lnum = lnum or 1,
              col = col or 1,
              text = text or match,
            })
          end
        end

        vim.fn.setqflist(list, "r")
      end,
    },
  },

  options = {
    content_from_bottom = false,
    use_cache = true,
  },
  -- Window related options
  window = {
    -- String to use as cursor in prompt
    prompt_caret = "|",

    -- String to use as prefix in prompt
    prompt_prefix = "",
  },
}
