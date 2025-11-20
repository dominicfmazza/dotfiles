vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function() vim.highlight.on_yank() end,
})

vim.api.nvim_create_user_command("Make", function(params)
  -- Insert args at the '$*' in the makeprg
  local cmd, num_subs = vim.o.makeprg:gsub("%$%*", params.args)
  if num_subs == 0 then cmd = cmd .. " " .. params.args end
  local task = require("overseer").new_task {
    cmd = vim.fn.expandcmd(cmd),
    components = {
      { "on_output_quickfix", open = not params.bang },
      "default",
    },
  }
  task:start()
end, {
  desc = "Run your makeprg as an Overseer task",
  nargs = "*",
  bang = true,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "help", "man", "terminal", "qf" },
  command = "wincmd L",
})

local function file_exists_in_cwd(filename)
  local cwd = vim.fn.getcwd()
  local full_path = cwd .. "/" .. filename

  -- Check if the file exists using vim.loop.fs_stat
  local stat = vim.loop.fs_stat(full_path)
  if stat and stat.type == "file" then
    return true
  else
    return false
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("MyFileOpenGroup", { clear = true }),
  callback = function(_)
    if file_exists_in_cwd "CMakeLists.txt" then
      vim.g.current_compiler = "cmake"

      vim.opt.makeprg = "cmake\\ $*"

      vim.opt.errorformat = {
        "%-G%f:%s:,",
        "%f:%l:%c: %trror: %m,",
        "%f:%l:%c: %tarning: %m,",
        "%I%f:%l:%c: note: %m,",
        "%f:%l:%c: %m,",
        "%f:%l: %trror: %m,",
        "%f:%l: %tarning: %m,",
        "%I%f:%l: note: %m,",
        "%f:%l: %m",
      }
    end
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.server_capabilities then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
})
-- Auto resize splits when the terminal's window is resized
vim.api.nvim_create_autocmd("VimResized", {
  command = "wincmd =",
})
