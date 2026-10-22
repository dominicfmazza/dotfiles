local api, fn = vim.api, vim.fn

--- @param name string
--- @return {bg?:integer, fg?:integer}
local function get_hl(name) return api.nvim_get_hl(0, { name = name }) end

--- @param tabnr integer
--- @return string
local function title(tabnr) return fn.fnamemodify(fn.getcwd(-1, tabnr), ":t") end

local function flags(bufnr)
  local ret = {} --- @type string[]
  if vim.bo[bufnr].buftype == "terminal" then return "" end
  if vim.bo[bufnr].modified then ret[#ret + 1] = "[+]" end
  if not vim.bo[bufnr].modifiable then ret[#ret + 1] = "[RO]" end
  return table.concat(ret)
end


local function separator(index)
  local selected = fn.tabpagenr()
  -- Don't add separator before or after selected
  if selected == index or selected - 1 == index then return " " end
  return index < fn.tabpagenr "$" and "%#FloatBorder#│" or ""
end


--- @param index integer
--- @param selected boolean
--- @return string
local function cell(index, selected)
  local buflist = fn.tabpagebuflist(index)
  local winnr = fn.tabpagewinnr(index)
  local bufnr = buflist[winnr]

  local bufnrs = vim.tbl_filter(function(b) return vim.bo[b].buftype ~= "nofile" end, buflist)

  local hl = not selected and "TabLineFill" or "TabLineSel"
  local common = "%#" .. hl .. "#"
  local ret = string.format("%s%%%dT %s%s ", common, index, title(index), flags(bufnr))

  if #bufnrs > 1 then ret = string.format("%s%s(%d) ", ret, common, #bufnrs) end

  return ret .. "%T" .. separator(index)
end

local M = {}

M.tabline = function()
  local parts = {} --- @type string[]

  local len = 0

  local sel_start --- @type integer

  for i = 1, fn.tabpagenr "$" do
    local selected = fn.tabpagenr() == i

    local part = cell(i, selected)

    --- @type integer
    local width = api.nvim_eval_statusline(part, { use_tabline = true }).width

    if selected then sel_start = len end

    len = len + width

    -- Make sure the start of the selected tab is always visible
    if sel_start and len > sel_start + vim.o.columns then break end

    parts[#parts + 1] = part
  end
  return table.concat(parts) .. "%#TabLineFill#%="
end

local function hldefs()
  for _, hl_base in ipairs { "TabLineSel", "TabLineFill" } do
    local bg = get_hl(hl_base).bg
    for _, ty in ipairs { "Warn", "Error", "Info", "Hint" } do
      local hl = get_hl("Diagnostic" .. ty)
      local name = ("Diagnostic%s%s"):format(ty, hl_base)
      api.nvim_set_hl(0, name, { fg = hl.fg, bg = bg })
    end
  end
end

local group = api.nvim_create_augroup("tabline", {})
api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = hldefs,
})
hldefs()

vim.opt.tabline = "%!v:lua.require'tabline'.tabline()"

return M
