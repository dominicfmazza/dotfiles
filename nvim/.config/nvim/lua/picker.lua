require("mini.pick").setup {
  delay = {
    async = 10,
    busy = 30,
  },

  mappings = {
    move_down = "<C-j>",
    move_up = "<C-k>",
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
    load_temp_rg(function() pick.builtin.files { tool = "rg" } end)
  end}

local picker = require "mini.pick"

-- Add custom pickers to registry
pickers = vim.tbl_extend("force", pickers, picker.builtin)
picker.registry = pickers

-- Bind keys enabling quick access to pickers
set_keymap("<F1>", pickers.help)
set_keymap("<leader>ff", pickers.ffiles)
set_keymap("<leader>fb", pickers.buffers)
set_keymap("<leader>fg", pickers.greppier)
set_keymap("<leader>fq", function() MiniExtra.pickers.list { scope = "quickfix" } end)
set_keymap("<leader>fl", function() MiniExtra.pickers.list { scope = "location" } end)
