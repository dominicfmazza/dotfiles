local overseer = require "overseer"
local get_presets = function(opts) return vim.fs.find("CMakePresets.json", { upward = true, type = "file", path = opts.dir })[1] end
local TAG = overseer.constants.TAG

local tmpl = {
  name = "preset",
  priority = 60,
  tags = { TAG.BUILD },
  params = {
    args = { optional = true, type = "list", delimiter = " " },
    cwd = { optional = true },
  },
  builder = function(params)
    return {
      cmd = { "cmake" },
      args = params.args,
      cwd = params.cwd,
    }
  end,
}

return {
  generator = function(opts, cb)
    local preset_file = assert(get_presets(opts))
    local cwd = vim.fs.dirname(preset_file)

    local ret = {}
    local cmd = { "cmake", "--workflow", "--list-presets" }
    local jid = vim.fn.jobstart(cmd, {
      cwd = cwd,
      stdout_buffered = true,
      on_stdout = vim.schedule_wrap(function(_, output)
        assert(output)
        vim.print(output)
        vim.print(_)
        local presets = require("overseer.cmakeutils").parse_preset_list(output)
        for _, target in ipairs(presets) do
          table.insert(
            ret,
            overseer.wrap_template(tmpl, {
              name = string.format("Preset %s", target),
            }, {
              args = { "--workflow", string.format("--preset=%s", target) },
              cwd = cwd,
            })
          )
          table.insert(
            ret,
            overseer.wrap_template(tmpl, {
              name = string.format("Preset %s - Fresh", target),
            }, {
              args = { "--workflow", string.format("--preset=%s", target), "--fresh" },
              cwd = cwd,
            })
          )
        end
        cb(ret)
      end),
    })
    if jid == 0 then
      require("overseer.log"):error "CMakePresets Failed"
      cb(ret)
    elseif jid == -1 then
      require("overseer.log"):error "CMakePresets Failed"
      cb(ret)
    end
  end,
  condition = {
    callback = function()
      if vim.fn.executable "cmake" == 0 then return false, 'Command "cmake" not found' end
      return true
    end,
  },
  cache_key = function(opts) return get_presets(opts) end,
}
