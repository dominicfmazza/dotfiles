require("fzf-lua").setup {
  { "hide" },
  fzf_bin = "sk",
  actions = {
    files = {
      ["enter"] = FzfLua.actions.file_edit_or_qf,
      ["ctrl-s"] = FzfLua.actions.file_split,
      ["ctrl-v"] = FzfLua.actions.file_vsplit,
      ["ctrl-t"] = FzfLua.actions.file_tabedit,
      ["alt-i"] = FzfLua.actions.toggle_ignore,
      ["alt-h"] = FzfLua.actions.toggle_hidden,
      ["alt-f"] = FzfLua.actions.toggle_follow,
      ["ctrl-q"] = FzfLua.actions.file_sel_to_qf,
      ["ctrl-Q"] = FzfLua.actions.file_sel_to_ll,
    },
  },
  buffers = {
    cwd_only = true,
  },
}

vim.keymap.set("n", "<leader>fb", function() require("fzf-lua").buffers() end, { desc = "Find Buffers" })
vim.keymap.set("n", "<leader>ff", function() require("fzf-lua").global() end, { desc = "Find Global" })
vim.keymap.set("n", "<leader>ft", "<cmd>TodoFzfLua<cr>", { desc = "Find TODOs" })
vim.keymap.set("n", "<leader>fg", function() require("fzf-lua").grep_project { hidden = true } end, { desc = "Live Grep" })
vim.keymap.set("n", "<leader>f/", function() require("fzf-lua").blines() end, { desc = "Current Buffer" })
vim.keymap.set("n", "<leader>fw", function() require("fzf-lua").grep_cword() end, { desc = "Find word under cursor" })


-- Each entry is the parent directory of a `.git` dir or file. A `.git` file
-- marks a worktree or a submodule.
local function pick_repo()
  local roots = { vim.fn.expand "~/repos", vim.fn.expand "~/dotfiles" }
  local cmd = "fd --hidden --no-ignore --max-depth 3 --format '{//}' '^\\.git$' "
    .. table.concat(vim.tbl_map(vim.fn.shellescape, roots), " ")
    .. " | sed 's|^"
    .. vim.env.HOME
    .. "/|~/|' | sort -u"
  require("fzf-lua").fzf_exec(cmd, {
    prompt = "Repos> ",
    actions = {
      ["enter"] = function(selected)
        if not selected[1] then return end
        local dir = vim.fn.expand(selected[1])
        vim.cmd.tabnew()
        vim.cmd.tcd(vim.fn.fnameescape(dir))
      end,
    },
  })
end

vim.keymap.set("n", "<leader>fr", pick_repo, { desc = "Find Repo (new tab)" })
