local M = {}
M.magiclines = function(str)
  local pos = 1
  return function()
    if not pos then return nil end
    local p1, p2 = string.find(str, "\r?\n", pos)
    local line
    if p1 then
      line = str:sub(pos, p1 - 1)
      pos = p2 + 1
    else
      line = str:sub(pos)
      pos = nil
    end
    return line
  end
end
M.isempty = function(s) return s == nil or s == "" end

M.parse_preset_list = function(output)
  local presets = {}
  for i, line in ipairs(output) do
    if i >= 2 and not M.isempty(line) then
      line = line.gsub(line, '"', "")
      line = line.gsub(line, "%s+", "")
      table.insert(presets, line)
    end
  end
  return presets
end

return M
