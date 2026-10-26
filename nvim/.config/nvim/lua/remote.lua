-- Talk to the oob server on the local machine through the socket on this host.
-- Neovim speaks the protocol itself, so the host needs no python3.

local M = {}

local uv = vim.uv
local SCHEMES = { http = true, https = true, mailto = true }

local function in_ssh() return vim.env.SSH_CONNECTION ~= nil or vim.env.SSH_TTY ~= nil end

local function has_display() return vim.env.DISPLAY ~= nil or vim.env.WAYLAND_DISPLAY ~= nil end

-- The socket path of the oob channel, or nil when this Neovim is local.
function M.socket()
  local path = vim.env.OOB_SOCK
  if not path or path == "" then
    local local_linux = vim.fn.has "linux" == 1 and vim.fn.has "wsl" == 0 and not has_display()
    if not (in_ssh() or local_linux) then return nil end
    path = vim.fs.normalize("~/.local/state/oob/" .. uv.os_gethostname() .. ".sock")
  end
  local stat = uv.fs_stat(path)
  if stat and stat.type == "socket" then return path end
  return nil
end

function M.active() return M.socket() ~= nil end

function M.request(req, timeout_ms)
  local path = M.socket()
  if not path then return nil, "no oob socket on this host" end
  local pipe = assert(uv.new_pipe(false))
  local buf, done, err = {}, false, nil

  local function finish(e)
    if done then return end
    done, err = true, e
    if not pipe:is_closing() then pipe:close() end
  end

  pipe:connect(path, function(cerr)
    if cerr then return finish(cerr) end
    pipe:write(vim.json.encode(req) .. "\n")
    pipe:read_start(function(rerr, chunk)
      if rerr then return finish(rerr) end
      if not chunk then return finish(nil) end
      buf[#buf + 1] = chunk
      if chunk:find("\n", 1, true) then finish(nil) end
    end)
  end)

  -- The answer must reach the caller before the timeout, so the loop polls.
  vim.wait(timeout_ms or 5000, function() return done end, 10)
  if not done then
    finish "timeout"
    return nil, "no answer from the local machine in time"
  end
  if err then return nil, tostring(err) end
  local line = table.concat(buf):match "^[^\n]*"
  if not line or line == "" then return nil, "no answer from the local machine. Run `oob up HOST` there." end
  local ok, resp = pcall(vim.json.decode, line)
  if not ok or type(resp) ~= "table" then return nil, "bad answer from the oob server" end
  if not resp.ok then return nil, resp.error or "the request failed" end
  return resp, nil
end

local function osc8(url)
  local seq = string.format("\027]8;;%s\027\\%s\027]8;;\027\\", url, url)
  if vim.env.TMUX then seq = "\027Ptmux;" .. seq:gsub("\027", "\027\027") .. "\027\\" end
  io.stdout:write(seq)
end

local function remote_url(target)
  local scheme = target:match "^(%a[%w+.-]*):"
  return scheme and SCHEMES[scheme:lower()] and target or nil
end

local original_open = vim.ui.open

-- Open a URL on the local machine. A path or a file URL opens on this host.
---@diagnostic disable-next-line: duplicate-set-field
vim.ui.open = function(target, opt)
  local url = remote_url(target)
  if not url or not in_ssh() and not M.active() then return original_open(target, opt) end
  local _, err = M.request { op = "open", url = url }
  if err then
    osc8(url)
    vim.notify(string.format("oob: %s\nOpen the link by hand: %s", err, url), vim.log.levels.WARN)
  end
  return nil, nil
end

function M.copy(text)
  local _, err = M.request { op = "copy", text = text }
  return err == nil, err
end

function M.paste()
  local resp, err = M.request { op = "paste" }
  if not resp then return nil, err end
  return resp.text, nil
end

function M.forward(port)
  port = tonumber(port)
  if not port then return vim.notify("oob: the port must be a number", vim.log.levels.ERROR) end
  local resp, err = M.request({ op = "forward", port = port }, 15000)
  if not resp then return vim.notify("oob: " .. err, vim.log.levels.ERROR) end
  vim.notify("oob: localhost:" .. port .. " forwards to the local machine")
end

vim.api.nvim_create_user_command("OobForward", function(cmd)
  local port = cmd.args
  if port == "" then
    local url = require("vim.ui")._get_urls()[1] or ""
    port = url:match "^https?://[^/:]+:(%d+)"
  end
  if not port then return vim.notify("oob: give a PORT, or put the cursor on a localhost URL", vim.log.levels.ERROR) end
  M.forward(port)
end, { nargs = "?", desc = "Forward a port on this host to the local machine" })

vim.api.nvim_create_user_command("OobPing", function()
  local path = M.socket()
  if not path then return vim.notify "oob: local mode, no channel" end
  local resp, err = M.request { op = "ping" }
  if not resp then return vim.notify("oob: " .. path .. " is down: " .. err, vim.log.levels.WARN) end
  vim.notify(string.format("oob: up on %s (host alias %s, paste %s)", path, resp.host, resp.paste and "on" or "off"))
end, { desc = "Test the oob channel" })

return M
