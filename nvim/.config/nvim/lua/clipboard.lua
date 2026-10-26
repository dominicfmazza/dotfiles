-- Copy and paste across the platforms that these dotfiles run on.
-- WSL reaches the Windows clipboard through clip.exe and powershell.exe.

local remote = require "remote"

local function has(cmd) return vim.fn.executable(cmd) == 1 end

local is_wsl = vim.fn.has "wsl" == 1 or vim.env.WSL_DISTRO_NAME ~= nil
local is_ssh = vim.env.SSH_CONNECTION ~= nil or vim.env.SSH_TTY ~= nil

-- A clipboard tool works on Linux only with a display server.
local has_local_tool = has "pbcopy" or has "termux-clipboard-set" or (vim.env.WAYLAND_DISPLAY and has "wl-copy") or (vim.env.DISPLAY and (has "xclip" or has "xsel"))

-- An SSH session uses the oob channel. OSC 52 is the fallback for copy.
local function oob_clipboard()
  local osc52 = require "vim.ui.clipboard.osc52"
  local function copy(reg)
    local fallback = osc52.copy(reg)
    return function(lines, regtype)
      local ok = remote.active() and remote.copy(table.concat(lines, "\n"))
      if not ok then fallback(lines, regtype) end
    end
  end
  -- Most terminals refuse to return the clipboard, so paste falls back to
  -- the unnamed register, as :help clipboard-osc52 shows.
  local function paste()
    local text = remote.active() and remote.paste()
    if text then return { vim.split(text, "\n", { plain = true }), "v" } end
    return { vim.fn.split(vim.fn.getreg "", "\n"), vim.fn.getregtype "" }
  end
  return {
    name = "oob",
    copy = { ["+"] = copy "+", ["*"] = copy "*" },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end

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
  vim.g.clipboard = oob_clipboard()
end

vim.opt.clipboard = "unnamedplus"
