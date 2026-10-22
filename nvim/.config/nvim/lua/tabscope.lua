-- Each tab keeps its own buffer list. Other tabs hide their buffers.
-- Buffers that were never listed (ergoterm terminals) stay as they are.

local api = vim.api

--- @type table<integer, table<integer, true>> tabpage handle -> buffer set
local tabs = {}

--- Buffers that this module lists and unlists.
--- @type table<integer, true>
local known = {}

-- A change to 'buflisted' fires BufAdd and BufDelete. The handlers ignore
-- those events while this flag is true.
local busy = false

local function set_listed(buf, value)
  if vim.bo[buf].buflisted ~= value then vim.bo[buf].buflisted = value end
end

local function tab_set(tab)
  tabs[tab] = tabs[tab] or {}
  return tabs[tab]
end

local function track(buf)
  if busy or not api.nvim_buf_is_valid(buf) or not vim.bo[buf].buflisted then return end
  tab_set(api.nvim_get_current_tabpage())[buf] = true
  known[buf] = true
end

local function forget(buf)
  if busy then return end
  for _, set in pairs(tabs) do
    set[buf] = nil
  end
  known[buf] = nil
end

local function leave()
  busy = true
  local set = {}
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted then
      set[buf] = true
      known[buf] = true
      set_listed(buf, false)
    end
  end
  tabs[api.nvim_get_current_tabpage()] = set
  busy = false
end

-- At TabEnter, the window of a new tab still shows the buffer of the old
-- tab. A new tab has no set yet, so it skips the window scan.
local function enter()
  busy = true
  local tab = api.nvim_get_current_tabpage()
  local is_new = tabs[tab] == nil
  local set = tab_set(tab)
  if not is_new then
    for _, win in ipairs(api.nvim_tabpage_list_wins(tab)) do
      local buf = api.nvim_win_get_buf(win)
      if known[buf] then set[buf] = true end
    end
  end
  for buf in pairs(set) do
    if api.nvim_buf_is_valid(buf) then
      set_listed(buf, true)
    else
      set[buf] = nil
    end
  end
  busy = false
end

-- A modified buffer of a closed tab moves to the current tab.
-- Other buffers of a closed tab stay unlisted. `:ls!` shows them.
local function new_entered()
  local buf = api.nvim_get_current_buf()
  if not known[buf] then return end
  busy = true
  set_listed(buf, true)
  busy = false
  tab_set(api.nvim_get_current_tabpage())[buf] = true
end

local function closed()
  local valid = {}
  for _, tab in ipairs(api.nvim_list_tabpages()) do
    valid[tab] = true
  end

  local orphans = {}
  for tab, set in pairs(tabs) do
    if not valid[tab] then
      for buf in pairs(set) do
        orphans[buf] = true
      end
      tabs[tab] = nil
    end
  end

  for _, set in pairs(tabs) do
    for buf in pairs(set) do
      orphans[buf] = nil
    end
  end

  for buf in pairs(orphans) do
    if api.nvim_buf_is_valid(buf) and vim.bo[buf].modified then
      busy = true
      set_listed(buf, true)
      busy = false
      track(buf)
    end
  end
end

local group = api.nvim_create_augroup("tabscope", {})
api.nvim_create_autocmd({ "BufAdd", "BufEnter" }, { group = group, callback = function(ev) track(ev.buf) end })
api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, { group = group, callback = function(ev) forget(ev.buf) end })
api.nvim_create_autocmd("TabLeave", { group = group, callback = leave })
api.nvim_create_autocmd("TabEnter", { group = group, callback = enter })
api.nvim_create_autocmd("TabNewEntered", { group = group, callback = new_entered })
api.nvim_create_autocmd("TabClosed", { group = group, callback = closed })

return {
  --- @param tab? integer tabpage handle, default is the current tab
  --- @return integer[]
  buffers = function(tab)
    tab = tab or api.nvim_get_current_tabpage()
    if tab == api.nvim_get_current_tabpage() then
      return vim.tbl_filter(function(b) return vim.bo[b].buflisted end, api.nvim_list_bufs())
    end
    return vim.tbl_keys(tabs[tab] or {})
  end,
}
