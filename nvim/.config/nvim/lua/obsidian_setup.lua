local map = vim.keymap.set

local function get_directories(parent_path)
  -- Get all entries in the directory that are directories
  local directories = {}

  for name, type in vim.fs.dir(parent_path, { depth = 1 }) do
    if type == "directory" then table.insert(directories, { name = vim.fs.basename(name), path = string.format("%s/%s", parent_path, name) }) end
  end
  return directories
end
local function determine_obsidian_workspaces()
  local obsidian_dir = vim.fn.expand "$HOME/vaults"
  if vim.env.OBSIDIAN_VAULT_ROOT then obsidian_dir = vim.env.OBSIDIAN_VAULT_ROOT end
  return get_directories(obsidian_dir)
end

local workspaces = determine_obsidian_workspaces()

-- Guards against the workspace being empty or undefined.
-- Does not handle an improperly specified workspace, but
-- since this is just for me, doesn't particularly matter.
if vim.tbl_count(workspaces) > 0 then
  require("obsidian").setup {
    legacy_commands = false,
    ui = { enable = false },
    workspaces = workspaces,
    picker = {
      name = "fzf-lua",
    },
    daily_notes = {
      folder = "notes/dailies",
    },
    note_id_func = function(title)
      local suffix = ""
      if title ~= nil then
        -- If title is given, transform it into valid file name.
        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      else
        -- If title is nil, just add 4 random uppercase letters to the suffix.
        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90))
        end
      end
      return suffix
    end,
  }

  map("n", "<leader>os", "<cmd>Obsidian quick_switch<cr>", { desc = "Obsidian: Search Files" })
  map("n", "<leader>on", "<cmd>Obsidian new<cr>", { desc = "Obsidian: New File" })
  map("n", "<leader>od", "<cmd>Obsidian dailies -4 4<cr>", { desc = "Obsidian: Dailies" })
  map("n", "<leader>ot", "<cmd>Obsidian today<cr>", { desc = "Obsidian: Today" })
  map("n", "<leader>oy", "<cmd>Obsidian yesterday<cr>", { desc = "Obsidian: Yesterday" })
  map("n", "<leader>oT", "<cmd>Obsidian tomorrow<cr>", { desc = "Obsidian: Tomorrow" })
  map("n", "<leader>ow", "<cmd>Obsidian workspace<cr>", { desc = "Obsidian: Workspaces" })
  map("n", "<leader>ox", "<cmd>Obsidian extract_note<cr>", { desc = "Obsidian: Extract Note" })
  map("n", "<leader>ol", "<cmd>Obsidian link<cr>", { desc = "Obsidian: Link Note" })
  map("n", "<leader>oL", "<cmd>Obsidian link_new<cr>", { desc = "Obsidian: Create and Link Note" })
else
  vim.notify("Workspace directory not specified", vim.log.levels.WARN, { title = "obsidian.lua" })
end
