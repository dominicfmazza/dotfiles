require("ergoterm").setup {
  terminal_defaults = {
    layout = "right",
    cleanup_on_success = false,
    auto_scroll = false,
    persist_mode = true,
    persist_size = false
  },
  picker = {
    picker = "fzf-lua",
    extra_select_actions = {
      ["<C-d>"] = { fn = function(term) term:cleanup() end, desc = "Delete terminal" },
    },
  },
}

vim.opt.scrollback = 10000

local map = vim.keymap.set
local ergoterm = require "ergoterm"

-- A mouse click leaves terminal mode before WinLeave, so persist_mode saves
-- normal mode. This WinLeave runs after the ergoterm one and saves insert.
local mouse_keys = {
  [vim.keycode "<LeftMouse>"] = true,
  [vim.keycode "<RightMouse>"] = true,
  [vim.keycode "<MiddleMouse>"] = true,
}
local clicked_in_insert = nil

vim.on_key(function(key)
  if not mouse_keys[key] or vim.api.nvim_get_mode().mode ~= "t" then return end
  clicked_in_insert = vim.api.nvim_get_current_buf()
  vim.schedule(function() clicked_in_insert = nil end)
end, vim.api.nvim_create_namespace "ergoterm_mouse_mode")

vim.api.nvim_create_autocmd("WinLeave", {
  group = vim.api.nvim_create_augroup("ErgoTermMouseMode", { clear = true }),
  pattern = "term://*",
  callback = function(args)
    if clicked_in_insert ~= args.buf then return end
    clicked_in_insert = nil
    local term = ergoterm.identify()
    if term and term.persist_mode then term._state.mode = "i" end
  end,
})

-- Open terminal picker
map("n", "<leader>tl", ":TermSelect<CR>", { noremap = true, silent = true, desc = "Terminal picker" })

-- Send text to last focused terminal
map({ "n", "x" }, "<leader>ts", ":TermSend! new_line=false<CR>", { noremap = true, silent = true, desc = "Send text to last focused terminal" })

-- Send and show output without focusing terminal
map({ "n", "x" }, "<leader>tx", ":TermSend! action=open<CR>", { noremap = true, silent = true, desc = "Send without focusing" })

map({ "x", "n", "t" }, "<M-'>", "<cmd>tabnext<CR>", { noremap = true, silent = true, desc = "" })
map({ "x", "n", "t" }, "<M-;>", "<cmd>tabprevious<CR>", { noremap = true, silent = true, desc = "" })

local function get_unique_wd_name(cwd)
  -- Get current directory and split by separator
  local path_parts = vim.split(cwd, "/", { trimempty = true })
  local initials = {}

  -- Iterate through path components (skipping last one if needed)
  for i, part in ipairs(path_parts) do
    if i < #path_parts then table.insert(initials, part:sub(1, 1)) end
  end

  return table.concat(initials, "-") .. "-" .. vim.fn.fnamemodify(cwd, ":t")
end

local function current_tab_cwd()
  local tab = vim.api.nvim_tabpage_get_number(vim.api.nvim_get_current_tabpage())
  return vim.fn.getcwd(-1, tab)
end

local function resolve_term_name(config)
  if config.name then return config.name end
  return config.name_prefix .. get_unique_wd_name(current_tab_cwd())
end

local function toggle_terminal(config, layout)
  local name = resolve_term_name(config)
  local server = ergoterm.find(function(term) return term.name == name end)
  if server then
    server:toggle()
    return
  end

  local term_opts = {
    layout = layout,
    name = name,
  }

  if config.cmd then term_opts.cmd = config.cmd end
  if config.cleanup_on_success ~= nil then term_opts.cleanup_on_success = config.cleanup_on_success end

  ergoterm:new(term_opts)
end

local float_terminal_maps = {
  { lhs = "<M-g>", name_prefix = "lg-", cmd = "lazygit", cleanup_on_success = true, desc = "Open Lazygit window" },
  { lhs = "<M-f>", name_prefix = "shell-", desc = "Open project shell" },
  { lhs = "<M-r>", name = "scratch", desc = "Open scratch space" },
}

local side_terminal_maps = {
  { lhs = "<M-c>", name_prefix = "ai-", cmd = "zsh -l -c pi", cleanup_on_success = true, desc = "Open Claude window" },
}

for _, config in ipairs(float_terminal_maps) do
  map({ "x", "n", "t" }, config.lhs, function() toggle_terminal(config, "float") end, { noremap = true, silent = true, desc = config.desc })
end

for _, config in ipairs(side_terminal_maps) do
  map({ "x", "n", "t" }, config.lhs, function() toggle_terminal(config, "right") end, { noremap = true, silent = true, desc = config.desc })
end


local function move_current_term(layout)
  local term = ergoterm.identify() or ergoterm.get_focused()
  if not term then
    vim.notify("No ergoterm terminal found", vim.log.levels.WARN)
    return
  end

  term:close()
  term:update { layout = layout }
  term:focus(layout)
end

local function move_term_bind(keymap, direction)
  vim.keymap.set("n", "<leader>t" .. keymap, function() move_current_term(direction) end, { desc = "Move terminal left" })
end

move_term_bind("h", "left")
move_term_bind("l", "right")
move_term_bind("j", "below")
move_term_bind("k", "above")
move_term_bind("f", "float")
move_term_bind("t", "tab")
