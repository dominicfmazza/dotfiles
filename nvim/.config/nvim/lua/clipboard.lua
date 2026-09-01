-- Clipboard support across the platforms these dotfiles run on.
--
-- Order of preference:
--   1. WSL: clip.exe and powershell.exe reach the Windows clipboard.
--   2. A local session with a clipboard tool: let Neovim pick it.
--   3. A remote or headless session: OSC 52, so the terminal carries the
--      text back to the machine the user sits at.

local function has(cmd) return vim.fn.executable(cmd) == 1 end

local is_wsl = vim.fn.has "wsl" == 1 or vim.env.WSL_DISTRO_NAME ~= nil
local is_ssh = vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil

local has_local_tool = has "wl-copy"
  or has "xclip"
  or has "xsel"
  or has "pbcopy"
  or has "termux-clipboard-set"

if is_wsl then
  vim.g.clipboard = {
    name = "WslClipboard",
    copy = {
      ["+"] = "clip.exe",
      ["*"] = "clip.exe",
    },
    paste = {
      ["+"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      ["*"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    },
    cache_enabled = 0,
  }
elseif is_ssh or not has_local_tool then
  -- OSC 52 needs no helper binary. A paste reads the Neovim register,
  -- because most terminals refuse to hand the clipboard back.
  vim.g.clipboard = {
    name = "OSC52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy "+",
      ["*"] = require("vim.ui.clipboard.osc52").copy "*",
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste "+",
      ["*"] = require("vim.ui.clipboard.osc52").paste "*",
    },
  }
end

vim.opt.clipboard = "unnamedplus"
