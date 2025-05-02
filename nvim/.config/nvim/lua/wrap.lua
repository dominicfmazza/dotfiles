
local M = {}
M.wrapenabled = false

M.ToggleWrap = function()
  if M.wrapenabled then
    vim.g.linebreak = false
    vim.g.nowrap = true
    vim.keymap.del({ "n", "v" }, "j")
    vim.keymap.del({ "n", "v" }, "k")
    vim.keymap.del({ "n", "v" }, "0")
    vim.keymap.del({ "n", "v" }, "^")
    vim.keymap.del({ "n", "v" }, "$")
    M.wrapenabled = false
  else
    vim.g.wrap = true
    vim.g.linebreak = true
    vim.g.breakat = " \t;:,!?"
    vim.g.breakindentopt = { "shift:2", "sbr" }
    vim.keymap.set({ "n", "v" }, "j", "gj", { remap = false })
    vim.keymap.set({ "n", "v" }, "k", "gk", { remap = false })
    vim.keymap.set({ "n", "v" }, "0", "g0", { remap = false })
    vim.keymap.set({ "n", "v" }, "^", "g^", { remap = false })
    vim.keymap.set({ "n", "v" }, "$", "g$", { remap = false })
    M.wrapenabled = true
  end
end

return M
