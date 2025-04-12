local overseer = require "overseer"
local TAG = overseer.constants.TAG

local tmpl = {
  name = "preset",
  priority = 1,
  tags = { TAG.BUILD },
  params = {
    cmd = { optional = false },
    args = { optional = true, type = "list", delimiter = " " },
    cwd = { optional = true },
  },
  builder = function(params)
    return {
      cmd = params.cmd,
      args = params.args,
      cwd = params.cwd,
    }
  end,
}

return {
  generator = function(_, cb)
    local command = "cmake"
    local args = { "--build", "build", "-j" }
    if vim.fn.executable "direnv" == 1 then
      command = "direnv"
      table.insert(args, 1, "exec")
      table.insert(args, 2, ".")
      table.insert(args, 3, "cmake")
    end
    local ret = {}
    table.insert(
      ret,
      overseer.wrap_template(tmpl, {
        name = string.format "Build in 'build'",
      }, {
        cmd = command,
        args = args,
        cwd = vim.fn.getcwd(),
      })
    )
    cb(ret)
  end,
  condition = {
    callback = function()
      if vim.fn.executable "cmake" == 0 then return false, 'Command "cmake" not found' end
      return vim.fs.find("build", { upward = false, type = "directory", path = vim.fn.getcwd() }) ~= nil
    end,
  },
}
