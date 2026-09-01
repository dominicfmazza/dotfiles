--- Obsidian task manager.
---
--- Adds tasks to the daily note, searches every task in the vault, and
--- toggles task state. Tasks stay plain Obsidian Tasks plugin markdown, so
--- Obsidian keeps full control of them.
---
--- Parsing uses the markdown treesitter parser to find list items, then reads
--- the checkbox marker from the item line. The parser only marks `[ ]` and
--- `[x]`, so the marker read keeps support for the custom statuses of the
--- Tasks plugin (`[/]`, `[-]`, and so on). Code blocks never produce a list
--- item node, so fenced examples do not become tasks.

--- The name `require` used for this file, for example "tasks". `M.reload`
--- needs it, and `...` only holds it at chunk level.
local MODULE = ... or "tasks"

local M = {}

---@class TasksConfig
M.config = {
  --- Heading that holds tasks in a daily note.
  section = "Tasks",
  --- Status cycle order for the toggle action.
  order = { " ", "/", "x", "-" },
  --- Statuses that count as closed.
  closed = { x = true, ["-"] = true },
  --- Status used by the "complete" action.
  done = "x",
  --- Add the `✅ <date>` field when a task closes.
  done_date = true,
  --- Add the `➕ <date>` field to a new task.
  created_date = false,
  --- Sign shown for each status.
  icons = {
    [" "] = "󰄱",
    ["/"] = "󱎖",
    ["x"] = "󰄲",
    ["-"] = "󰅗",
    [">"] = "󰒭",
    ["?"] = "󰘥",
    ["!"] = "󰀦",
  },
  --- Highlight group for each status sign.
  hls = {
    [" "] = "Comment",
    ["/"] = "DiagnosticInfo",
    ["x"] = "DiagnosticOk",
    ["-"] = "DiagnosticError",
  },
  --- Name shown for each status in the menu and in the status groups.
  names = {
    [" "] = "To do",
    ["/"] = "In progress",
    ["x"] = "Done",
    ["-"] = "Cancelled",
    [">"] = "Forwarded",
    ["?"] = "Question",
    ["!"] = "Important",
  },
  --- Text between the note title and the task text in the picker.
  separator = "│",
  --- Highlight groups for the picker entry.
  picker_hl = { title = "Directory", separator = "Comment" },
  --- Milliseconds a parsed file stays trusted without a fresh stat. A write
  --- through this module always clears the entry, so this only delays picking
  --- up an edit made outside Neovim.
  cache_ms = 2000,
  --- Globs the vault scan skips. A template holds example task lines, so it
  --- would otherwise show as a project.
  exclude = { "Templates/**", "Archive/**", ".obsidian/**", ".claude/**" },
  --- Daily notes folder, used when obsidian.nvim is not set up.
  daily_folder = "Daily Notes",
  --- Every note that holds tasks carries a kind in its frontmatter. The kind
  --- decides whether the board shows the group, the same way a task status
  --- decides whether the board shows a task.
  note = {
    --- Frontmatter field that holds the kind.
    field = "status",
    --- The four kinds. `daily` belongs to a daily note, the other three to a
    --- project.
    kinds = { "daily", "project", "finished_project", "cancelled_project" },
    --- Kinds a project cycles through in the kind menu.
    project_kinds = { "project", "finished_project", "cancelled_project" },
    --- Kinds the board hides unless the filter is off.
    closed = { finished_project = true, cancelled_project = true },
    --- Name shown for each kind.
    names = {
      daily = "Daily",
      project = "Project",
      finished_project = "Finished",
      cancelled_project = "Cancelled",
    },
    --- Sign shown for each kind on a group heading.
    icons = {
      daily = "󰃰",
      project = "󰞵",
      finished_project = "󰨪",
      cancelled_project = "󰅙",
    },
    --- Highlight group for each kind on a group heading.
    hls = {
      daily = "Title",
      project = "Function",
      finished_project = "Comment",
      cancelled_project = "Comment",
    },
  },
  --- New project notes.
  project = {
    --- Folder inside the vault that holds the project notes.
    folder = "Projects",
    --- Headings written into a new note, in order. The first one must be the
    --- task heading, so `M.add_to` can find it.
    sections = { "Tasks", "Description" },
    --- Heading level for those sections.
    level = 2,
    --- Frontmatter written into a new note. A value may be a function. The
    --- kind field is added from `config.note`, so a new note always reads as
    --- an open project.
    frontmatter = {
      ---@return string
      start_date = function() return tostring(os.date "%Y-%m-%d") end,
    },
    --- Open the note after creating it.
    open = true,
  },
  --- Default board grouping.
  --- Date format for the ✅ and ➕ fields.
  date_format = "%Y-%m-%d",
  --- Board window and binds. The board is a normal-mode buffer, so plain
  --- keys work there.
  board = {
    --- Opens the board, the way the alt keys open the terminals. `<M-t>` is
    --- not usable: whkd and glazewm both bind `alt+t` to a float toggle, so
    --- the window manager takes the key before Neovim sees it.
    open_key = "<M-n>",
    title = " Tasks ",
    border = "rounded",
    zindex = 50,
    size = { width = "70%", height = "70%" },
    keys = {
      toggle = "<Tab>",
      menu = "<CR>",
      open = "o",
      add = "a",
      group = "g",
      filter = "f",
      search = "/",
      refresh = "r",
      project = "p",
      note_kind = "d",
      next = "<C-n>",
      prev = "<C-p>",
      help = "?",
      close = { "q", "<Esc>" },
    },
    --- Glyphs that shape the board. Every one is a nerd font sign.
    marks = {
      group = "󰞵",
      rule = "┄",
      indent = "│",
      fallback = "",
      empty = "󰗡",
      wait = "󰝲",
      filter = "󰈲",
      absent = "󰑕",
      select = "󰄬",
    },
    hl = {
      normal = "NormalFloat",
      border = "FloatBorder",
      cursor = "CursorLine",
      group = "Title",
      count = "Comment",
      text = "Normal",
      closed = "Comment",
      --- The tree rule and the indent guide.
      rule = "LineNr",
      --- The group icon.
      icon = "Function",
      --- A date, a tag, or a priority sign after the task text.
      field = "Comment",
      --- The visual-line selection.
      select = "Visual",
    },
  },
  --- Status menu window.
  menu = {
    title = " Status ",
    border = "rounded",
    hl = {
      normal = "NormalFloat",
      border = "FloatBorder",
      cursor = "PmenuSel",
      text = "Normal",
      mark = "Special",
    },
  },
  --- Picker binds. Every bind stays on ctrl, because the window manager
  --- (whkd and glazewm) owns most alt combinations. A bind here is a
  --- terminal-mode map, so it must not be a character you type in a query.
  keys = {
    --- Show the key list in a centered popup. `?` is the primary key, the
    --- same as on the board. A terminal-mode map takes the key before fzf
    --- reads it, so a literal `?` cannot go into the query. The alt chord
    --- stays as a second bind.
    help = { "?", "<M-?>" },
    --- Set the status to done.
    done = "ctrl-x",
    --- Step the status through `order`.
    cycle = "ctrl-r",
    --- Add the typed query as a task in today's note.
    add = "ctrl-y",
  },
  --- Help popup layout.
  help = {
    title = " Task keys ",
    border = "rounded",
    --- Highlight groups.
    hl = {
      normal = "NormalFloat",
      border = "FloatBorder",
      key = "Special",
      group = "Title",
      desc = "Normal",
    },
  },
}

--- Show a bind the way fzf spells it, for example `<C-g>` as `ctrl-g`.
--- A list of binds shows the first one.
---@param key string|string[]
---@return string label
local function key_label(key)
  local one = type(key) == "table" and key[1] or key
  ---@cast one string
  local label = one:lower():gsub("^<c%-(.+)>$", "ctrl-%1"):gsub("^<m%-(.+)>$", "alt-%1"):gsub("^<(.+)>$", "%1")
  -- Spell the named keys the way a reader says them.
  return ({ cr = "enter", esc = "escape", bs = "backspace", space = "space" })[label] or label
end

--- The Obsidian Tasks plugin field emoji.
local F = {
  done = "✅",
  created = "➕",
  due = "📅",
  scheduled = "⏳",
  start = "🛫",
  repeats = "🔁",
}

--- The sign shown for each field on the board.
local I = {
  done = "󰃰",
  created = "󰜄",
  due = "󰃳",
  scheduled = "󰔛",
  start = "󰤨",
  repeats = "󰑐",
  tag = "󰋽",
}

--- The sign shown for each Tasks plugin priority.
local PRIORITY = {
  ["⏫"] = "󰅃",
  ["🔼"] = "󰁝",
  ["🔽"] = "󰁞",
  ["⏬"] = "󰅀",
}

--- A bind spec as a list, so one key and many keys read the same.
---@param key string|string[]
---@return string[] keys
local function help_keys(key) return type(key) == "table" and key or { key } end

--- Turn off the fzf-lua help strip for every help key.
---@param key string|string[]
---@return table<string, false> builtin keymap
local function help_keymap(key)
  local map = {}
  for _, k in ipairs(help_keys(key)) do
    map[k] = false
  end
  return map
end

local DONE_FIELD = F.done
local CREATED_FIELD = F.created

--- Match a checkbox list item line.
---@param line string
---@return string? indent
---@return string? marker list bullet, for example "-" or "1."
---@return string? status single status character
---@return string? text task text after the checkbox
local function parse_line(line)
  local indent, marker, status, text = line:match "^(%s*)([-+*])%s+%[(.)%]%s*(.*)$"
  if not indent then
    indent, marker, status, text = line:match "^(%s*)(%d+[%.%)])%s+%[(.)%]%s*(.*)$"
  end
  return indent, marker, status, text
end

---@return string root absolute path of the vault
local function vault_root()
  ---@diagnostic disable-next-line: undefined-global
  local ob = rawget(_G, "Obsidian")
  if ob and ob.workspace then return tostring(ob.workspace.root) end
  local env = vim.env.OBSIDIAN_VAULT_ROOT
  if env and #env > 0 then return (env:gsub("/+$", "")) end
  return vim.fs.joinpath(vim.uv.os_homedir() or ".", "vaults")
end

---@return string date
local function today() return tostring(os.date(M.config.date_format)) end

---@param status string
---@return boolean
local function is_closed(status) return M.config.closed[status] == true end

---@param status string
---@return string next_status
local function next_status(status)
  local order = M.config.order
  for i, s in ipairs(order) do
    if s == status then return order[i % #order + 1] end
  end
  return order[1]
end

--- Rewrite the task text for a status change.
---@param text string
---@param status string new status
---@return string text
local function retext(text, status)
  local out = text
  if is_closed(status) then
    if M.config.done_date and not out:find(DONE_FIELD, 1, true) then out = out:gsub("%s*$", "") .. " " .. DONE_FIELD .. " " .. today() end
  else
    out = out:gsub("%s*" .. DONE_FIELD .. "%s*%d%d%d%d%-%d%d%-%d%d", "")
    out = out:gsub("%s*" .. DONE_FIELD .. "%s*$", "")
  end
  return (out:gsub("%s+$", ""))
end

--- Build a task line.
---@param indent string
---@param marker string
---@param status string
---@param text string
---@return string line
local function build_line(indent, marker, status, text) return string.format("%s%s [%s] %s", indent, marker, status, text) end

--- List vault files that hold at least one checkbox.
---@param root string
---@return string[] paths relative to the vault root
local function candidate_files(root)
  if vim.fn.executable "rg" == 1 then
    local args = { "rg", "--type=md", "--no-messages", "--files-with-matches", "--regexp", [[^\s*([-*+]|\d+[.)])\s+\[.\]\s]], "." }
    local out = vim.system(args, { cwd = root, text = true }):wait()
    if out.code == 0 or out.code == 1 then
      local files = {}
      for line in (out.stdout or ""):gmatch "[^\r\n]+" do
        files[#files + 1] = (line:gsub("^%./", ""))
      end
      return files
    end
  end

  -- No `rg`. Walk the tree instead. `vim.fs.dir` is a plain Lua iterator, so
  -- no `wildignore` setting can drop a note.
  local files = {}
  for name, kind in vim.fs.dir(root, { depth = 16 }) do
    if kind == "file" and name:sub(-3) == ".md" then files[#files + 1] = name end
  end
  return files
end

--- The loaded buffer for a path, or nil.
---
--- `vim.fn.bufnr()` scans every buffer name through a Vim regex, which costs
--- about 9 ms per call on a vault-sized path. One pass over the buffer list is
--- far cheaper, so the whole map builds at once.
--- Maps the absolute path of every loaded buffer to its number.
---@return table<string, integer> map
local function loaded_buffers()
  local map = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name ~= "" then map[name] = bufnr end
    end
  end
  return map
end

---@type table<string, integer>? buffer map for the current collect pass
local buffer_map = nil

--- The loaded buffer for a path, or nil.
---@param abs string absolute path
---@return integer? bufnr
local function buffer_for(abs)
  if buffer_map then return buffer_map[abs] end
  return loaded_buffers()[abs]
end

--- Read a file, or the loaded buffer when one holds newer text.
---@param abs string absolute path
---@return string[] lines
local function read_lines(abs)
  local bufnr = buffer_for(abs)
  if bufnr then return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false) end
  local ok, lines = pcall(vim.fn.readfile, abs)
  if not ok then return {} end
  return lines
end

---@class Task
---@field file string path relative to the vault root
---@field title string note title, for display
---@field kind NoteKind kind of the note that holds the task
---@field note_done boolean the kind is closed
---@field daily boolean the note is a daily note
---@field lnum integer 1-based line number
---@field status string single status character
---@field text string task text without the checkbox
---@field line string full raw line

---@alias NoteKind "daily"|"project"|"finished_project"|"cancelled_project"

---@class NoteInfo
---@field title string display name of the note
---@field kind NoteKind what the note is
---@field daily boolean the note is a daily note
---@field done boolean the kind is closed, so the board hides the group
---@field declared boolean the frontmatter names the kind, rather than a guess
---@field frontmatter table<string, string> raw scalar fields

--- The daily notes folder, relative to the vault root.
---@return string folder
function M.daily_folder()
  local ob = rawget(_G, "Obsidian")
  local folder = ob and ob.opts and ob.opts.daily_notes and ob.opts.daily_notes.folder
  return folder or M.config.daily_folder
end

--- Whether a path sits in the daily notes folder.
---@param rel string path relative to the vault root
---@return boolean
function M.is_daily_path(rel)
  local folder = M.daily_folder()
  return rel:sub(1, #folder + 1) == folder .. "/"
end

--- Read the frontmatter of a note, plus its display title.
---
--- A note counts as done when the field named by `config.note_done.field`
--- holds one of `config.note_done.values`. The board hides a done note, so a
--- finished project stops adding a heading to the list.
---@param rel string path relative to the vault root
---@param lines string[] file lines
---@return NoteInfo info
function M.note_info(rel, lines)
  local front = {}
  local title, heading

  local in_frontmatter = false
  for i, line in ipairs(lines) do
    if i == 1 and line:match "^%-%-%-%s*$" then
      in_frontmatter = true
    elseif in_frontmatter and line:match "^%-%-%-%s*$" then
      in_frontmatter = false
    elseif in_frontmatter then
      local key, value = line:match "^([%w_%-]+):%s*(.*)$"
      if key and value and value ~= "" then front[key:lower()] = (vim.trim(value):gsub("^[\"']", ""):gsub("[\"']$", "")) end
    elseif not heading then
      local text = line:match "^#%s+(.+)$"
      if text then heading = vim.trim(text) end
      if i > 40 then break end
    end
  end

  title = front.title or heading or (vim.fs.basename(rel):gsub("%.md$", ""))

  local cfg = M.config.note
  local kind = front[cfg.field:lower()]
  kind = kind and kind:lower():gsub("[%s%-]", "_") or nil

  -- An unknown or absent value falls back on the folder: a note under the
  -- daily folder is a daily note, anything else is an open project.
  local declared = kind ~= nil and vim.tbl_contains(cfg.kinds, kind)
  if not declared then kind = M.is_daily_path(rel) and "daily" or "project" end

  return {
    title = title,
    kind = kind,
    declared = declared,
    daily = kind == "daily",
    done = cfg.closed[kind] == true,
    frontmatter = front,
  }
end

--- Parsed tasks per file, keyed by the absolute path.
---
--- An entry holds the mtime, the size, and a content hash, so a file parses
--- once and reloads only after a real change. The vault sits on a network
--- drive, where the read and the parse dominate the board open cost.
---@type table<string, { mtime: integer, size: integer, hash: string, tasks: Task[], seen: integer }>
local parse_cache = {}

---@type table|false|nil built `(list_item)` query. `false` records a failure.
local item_query = nil

--- Drop the whole parse cache, and the built query.
function M.invalidate()
  parse_cache = {}
  item_query = nil
end

--- Hash the file content. `sha256` is a Neovim builtin, so this costs one call.
---@param lines string[]
---@return string hash
local function content_hash(lines) return vim.fn.sha256(table.concat(lines, "\n")) end

--- The `(list_item)` query, built once.
---
--- The query text never changes, so parsing it for every file was pure waste.
--- A `false` value records a failed build, so a broken markdown grammar does
--- not retry on every file.
---@return table? query
local function list_item_query()
  if item_query == nil then
    local ok, query = pcall(vim.treesitter.query.parse, "markdown", "(list_item) @item")
    item_query = ok and query or false
  end
  return item_query or nil
end

--- Store a parse result in the cache.
---
--- One place owns the field set, so a new field can never be missed on one of
--- the three write paths.
---@param abs string absolute path
---@param stat table? stat result. nil skips the store, as for a loaded buffer
---@param hash string?
---@param tasks Task[]
local function cache_put(abs, stat, hash, tasks)
  if not stat or not hash then return end
  parse_cache[abs] = { mtime = stat.mtime.sec, size = stat.size, hash = hash, tasks = tasks, seen = vim.uv.now() }
end

--- Collect every task in one file.
---
--- The cheap check runs first: the mtime and the size from a stat. When those
--- match, the cached tasks come back with no read at all. When they differ, the
--- file loads, and the content hash decides whether a parse is needed. A touch
--- with no edit keeps the cached tasks.
---@param root string
---@param rel string path relative to the vault root
---@return Task[] tasks
function M.parse_file(root, rel)
  local abs = vim.fs.joinpath(root, rel)

  -- A loaded buffer may hold text that the file does not, so never cache it.
  local buffered = buffer_for(abs) ~= nil

  local cached = not buffered and parse_cache[abs] or nil

  -- A stat costs about 3 ms on the network drive, so 20 of them dominate a
  -- redraw. Inside the freshness window, trust the cache without a stat. A
  -- write clears the entry, so an edit made here is always visible.
  if cached and (vim.uv.now() - cached.seen) < M.config.cache_ms then return cached.tasks end

  local stat = not buffered and vim.uv.fs_stat(abs) or nil
  if cached and stat and cached.mtime == stat.mtime.sec and cached.size == stat.size then
    cached.seen = vim.uv.now()
    return cached.tasks
  end

  local lines = read_lines(abs)
  if #lines == 0 then return {} end

  -- The stat changed. Hash the content, because a touch or a formatting pass
  -- often leaves the tasks alone.
  local hash = stat and content_hash(lines) or nil
  if stat and hash and cached and cached.hash == hash then
    cache_put(abs, stat, hash, cached.tasks)
    return cached.tasks
  end

  local query = list_item_query()
  if not query then return {} end

  local text = table.concat(lines, "\n")
  local ok, parser = pcall(vim.treesitter.get_string_parser, text, "markdown")
  if not ok or not parser then return {} end

  local tree = parser:parse()[1]
  if not tree then return {} end

  local tasks = {}
  local info = M.note_info(rel, lines)
  for _, node in query:iter_captures(tree:root(), text) do
    local row = node:start()
    local line = lines[row + 1]
    if line then
      local indent, marker, status, task_text = parse_line(line)
      if indent and marker and status then
        tasks[#tasks + 1] = {
          file = rel,
          title = info.title,
          kind = info.kind,
          note_done = info.done,
          daily = info.daily,
          lnum = row + 1,
          status = status,
          text = task_text or "",
          line = line,
        }
      end
    end
  end

  cache_put(abs, stat, hash, tasks)
  return tasks
end

--- Collect every task in the vault.
---
--- With `open_only`, two filters apply: a closed task drops out, and every
--- task of a closed note drops out too.
---@param opts { open_only?: boolean }?
---@return Task[] tasks
---@return string root
function M.collect(opts)
  opts = opts or {}
  local root = vault_root()

  -- One buffer scan for the whole pass.
  buffer_map = loaded_buffers()

  -- The same scan the board uses, so the picker and the board never disagree
  -- about which notes count.
  local tasks = {}
  for _, rel in ipairs((M.scan(root))) do
    for _, task in ipairs(M.parse_file(root, rel)) do
      -- A closed project drops out with `open_only`, whatever its task
      -- states are.
      local hide = opts.open_only and (task.note_done or is_closed(task.status))
      if not hide then tasks[#tasks + 1] = task end
    end
  end
  buffer_map = nil
  -- Newest note first, and document order inside a note. The board and the
  -- picker group the result, so the order stays stable across a redraw.
  table.sort(tasks, function(a, b)
    if a.file ~= b.file then return a.file > b.file end
    return a.lnum < b.lnum
  end)
  return tasks, root
end
--------------------------------------------------------------------------------
-- groups
--------------------------------------------------------------------------------

---@class Group
---@field key string sort key
---@field label string heading text
---@field kind NoteKind kind of the note behind the group
---@field file string? path relative to the vault root. Nil when no note exists.
---@field date integer? timestamp, for a daily group
---@field tasks Task[] tasks in the group
---@field done integer closed tasks in the group
---@field exists boolean the note exists on disk
---@field pinned boolean? the board always shows the group, empty or not
---@field suffix string? label shown after the heading, e.g. "Today"
---@field offset integer? day offset, for a pinned daily group

--- The daily note path for a day offset, and its id.
---@param offset integer days from today
---@return string rel path relative to the vault root
---@return string id file stem, which is the date
---@return integer stamp
local function daily_ref(offset)
  local stamp = os.time() + offset * 86400
  local ok, daily = pcall(require, "obsidian.daily")
  if ok then
    local path, id = daily.daily_note_path(stamp)
    local rel = tostring(path):sub(#vault_root() + 2)
    return rel, id, stamp
  end
  local id = tostring(os.date(M.config.date_format, stamp))
  return vim.fs.joinpath(M.daily_folder(), id .. ".md"), id, stamp
end

--- Does a path match one of the `exclude` globs?
---@param rel string path relative to the vault root
---@return boolean excluded
function M.excluded(rel)
  for _, glob in ipairs(M.config.exclude) do
    if vim.glob.to_lpeg(glob):match(rel) then return true end
  end
  return false
end

--- Every note the board cares about, in one `rg` pass.
---
--- A note qualifies when it holds a task line, or when it declares a note kind
--- in its frontmatter. The second case is what gives a fresh, empty project a
--- heading. One pass keeps the vault scan near the cost of a single search.
---@param root string
---@return string[] with_tasks paths that hold at least one task
---@return table<string, boolean> declared paths that name a kind
function M.scan(root)
  local cfg = M.config.note
  local task_re = [[^\s*([-*+]|\d+[.)])\s+\[.\]\s]]
  local kind_re = string.format([[^%s:[ \t]*["']?(%s)["']?[ \t]*$]], cfg.field, table.concat(cfg.kinds, "|"))

  if vim.fn.executable "rg" ~= 1 then
    -- No `rg`. Read each note and let `note_info` decide, which matches what
    -- the `rg` pass reports. This honours `exclude` too, so a template still
    -- stays off the board.
    local files, declared = {}, {}
    for _, rel in ipairs(candidate_files(root)) do
      if not M.excluded(rel) then
        files[#files + 1] = rel
        if M.note_info(rel, read_lines(vim.fs.joinpath(root, rel))).declared then declared[rel] = true end
      end
    end
    return files, declared
  end

  local args = { "rg", "--type=md", "--no-messages", "--ignore-case", "--no-heading", "--with-filename", "--only-matching", "--replace", "$1" }
  for _, glob in ipairs(M.config.exclude) do
    vim.list_extend(args, { "-g", "!" .. glob })
  end
  -- `$1` is empty for a task hit, and the kind for a frontmatter hit.
  vim.list_extend(args, { "--regexp", kind_re, "--regexp", task_re, "." })

  local out = vim.system(args, { cwd = root, text = true }):wait()
  if out.code ~= 0 and out.code ~= 1 then return {}, {} end

  local with_tasks, seen, declared = {}, {}, {}
  for line in (out.stdout or ""):gmatch "[^\r\n]+" do
    local rel, rest = line:match "^(.-):(.*)$"
    if rel then
      rel = rel:gsub("^%./", "")
      if rest ~= "" then
        declared[rel] = true
      elseif not seen[rel] then
        seen[rel] = true
        with_tasks[#with_tasks + 1] = rel
      end
    end
  end
  return with_tasks, declared
end

--- Group the tasks of the vault, and apply the visibility rules.
---
--- A group is a note that holds tasks, or a daily note that the board always
--- shows. The rules:
---
--- - A project shows always, even with no tasks, unless its kind is closed.
--- - A daily note shows only while it holds at least one open task. An old
---   daily note drops off the list once every task in it is closed.
--- - Today and Tomorrow show always, even with no tasks and no file.
--- - With `all`, every group shows, closed projects and finished dailies too.
---@param opts { all?: boolean }?
---@return Group[] groups
---@return string root
function M.groups(opts)
  opts = opts or {}
  local root = vault_root()

  -- One buffer scan for the whole pass.
  buffer_map = loaded_buffers()

  ---@type table<string, Group>
  local by_file = {}
  local order = {}

  ---@param rel string
  ---@param info { title: string, kind: NoteKind }
  ---@param exists boolean
  ---@return Group
  local function bucket(rel, info, exists)
    local g = by_file[rel]
    if not g then
      g = {
        key = rel,
        label = info.title,
        kind = info.kind,
        file = rel,
        tasks = {},
        done = 0,
        exists = exists,
      }
      by_file[rel] = g
      order[#order + 1] = rel
    end
    return g
  end

  local with_tasks, declared = M.scan(root)

  for _, rel in ipairs(with_tasks) do
    for _, task in ipairs(M.parse_file(root, rel)) do
      local g = bucket(rel, task, true)
      g.tasks[#g.tasks + 1] = task
      if is_closed(task.status) then g.done = g.done + 1 end
    end
  end

  -- A project with no task at all still deserves a heading, but only when it
  -- declares the kind itself. A plain reference note never becomes a group,
  -- which keeps a large vault off the board.
  for rel in pairs(declared) do
    if not by_file[rel] then
      local info = M.note_info(rel, read_lines(vim.fs.joinpath(root, rel)))
      if not info.daily then bucket(rel, info, true) end
    end
  end

  -- Today and Tomorrow always appear, even with no file.
  for _, spec in ipairs { { 0, "Today" }, { 1, "Tomorrow" } } do
    local offset, name = spec[1], spec[2]
    local rel, id, stamp = daily_ref(offset)
    local g = by_file[rel]
    if not g then g = bucket(rel, { title = id, kind = "daily" }, vim.uv.fs_stat(vim.fs.joinpath(root, rel)) ~= nil) end
    g.pinned = true
    g.date = stamp
    g.suffix = name
    g.offset = offset
  end

  buffer_map = nil

  -- Stamp each daily group with its date, for sorting.
  for _, g in pairs(by_file) do
    if g.kind == "daily" and not g.date then
      local y, m, d = (g.file or ""):match "(%d%d%d%d)%-(%d%d)%-(%d%d)%.md$"
      if y and m and d then g.date = os.time { year = tonumber(y) or 1970, month = tonumber(m) or 1, day = tonumber(d) or 1, hour = 12 } end
    end
  end

  -- Apply the visibility rules.
  local groups = {}
  for _, rel in ipairs(order) do
    local g = by_file[rel]
    local open = #g.tasks - g.done
    local show
    if opts.all then
      show = true
    elseif g.pinned then
      show = true -- Today and Tomorrow, always
    elseif M.config.note.closed[g.kind] then
      show = false -- a finished or a cancelled project
    elseif g.kind == "daily" then
      show = open > 0 -- an old daily note lives while it holds open work
    else
      show = true -- an open project, tasks or not
    end
    if show then groups[#groups + 1] = g end
  end

  -- Order: the pinned dailies first, newest first, then the other dailies,
  -- then the projects by name.
  ---@param g Group
  ---@return integer
  local function rank(g)
    if g.pinned then return 1 end
    if g.kind == "daily" then return 2 end
    return 3
  end
  table.sort(groups, function(a, b)
    local ra, rb = rank(a), rank(b)
    if ra ~= rb then return ra < rb end
    -- A project reads by name.
    if ra == 3 then return a.label:lower() < b.label:lower() end
    -- Today sits above Tomorrow, then the older notes, newest first.
    if ra == 1 then return (a.offset or 0) < (b.offset or 0) end
    return (a.date or 0) > (b.date or 0)
  end)

  -- Document order inside a group.
  for _, g in ipairs(groups) do
    table.sort(g.tasks, function(a, b) return a.lnum < b.lnum end)
  end
  return groups, root
end

--- Replace lines in a file, or in the loaded buffer. One write per file, so a
--- bulk status change costs one read and one write for each note.
---@param abs string absolute path
---@param changes table<integer, string> new line, keyed by the 1-based number
local function write_lines(abs, changes)
  if vim.tbl_isempty(changes) then return end
  parse_cache[abs] = nil

  local bufnr = buffer_for(abs)
  if bufnr then
    for lnum, line in pairs(changes) do
      vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, { line })
    end
    if not vim.bo[bufnr].modified then return end
    vim.api.nvim_buf_call(bufnr, function() vim.cmd "silent noautocmd write" end)
    return
  end

  local lines = vim.fn.readfile(abs)
  local dirty = false
  for lnum, line in pairs(changes) do
    if lines[lnum] then
      lines[lnum] = line
      dirty = true
    end
  end
  if not dirty then return end
  vim.fn.writefile(lines, abs)
end

--- Replace one line in a file, or in the loaded buffer.
---@param abs string absolute path
---@param lnum integer 1-based line number
---@param line string new line
local function write_line(abs, lnum, line) write_lines(abs, { [lnum] = line }) end

--- Set the status of one task.
---@param abs string absolute path
---@param lnum integer 1-based line number
---@param status string? new status. Cycles the status when nil.
---@return string? status the status that was written
function M.set_status(abs, lnum, status)
  local lines = read_lines(abs)
  local line = lines[lnum]
  if not line then return nil end
  local indent, marker, cur, text = parse_line(line)
  if not indent or not marker or not cur then return nil end
  local new = status or next_status(cur)
  write_line(abs, lnum, build_line(indent, marker, new, retext(text or "", new)))
  return new
end

--- Set the status of many tasks. Groups the work by file, so each note takes
--- one read and one write.
---@param tasks Task[] tasks to change
---@param status string? new status. Cycles each task when nil.
---@return integer count tasks that changed
function M.set_status_many(tasks, status)
  local root = vault_root()

  -- Bucket the line numbers by file.
  local by_file = {}
  for _, task in ipairs(tasks) do
    local abs = vim.fs.joinpath(root, task.file)
    by_file[abs] = by_file[abs] or {}
    table.insert(by_file[abs], task.lnum)
  end

  local count = 0
  for abs, lnums in pairs(by_file) do
    local lines = read_lines(abs)
    local changes = {}
    for _, lnum in ipairs(lnums) do
      local line = lines[lnum]
      if line then
        local indent, marker, cur, text = parse_line(line)
        if indent and marker and cur then
          local new = status or next_status(cur)
          changes[lnum] = build_line(indent, marker, new, retext(text or "", new))
          count = count + 1
        end
      end
    end
    write_lines(abs, changes)
  end
  return count
end

--- Toggle the task under the cursor in a note buffer.
---
--- No key maps this either. Reach it through `:Tasks toggle`.
function M.toggle_current()
  local bufnr = vim.api.nvim_get_current_buf()
  local abs = vim.api.nvim_buf_get_name(bufnr)
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)
  local line = lines[1]
  if not line then return end
  local indent, marker, cur, text = parse_line(line)
  if not indent or not marker or not cur then
    -- Turn a plain list item into a task.
    local plain_indent, plain_marker, rest = line:match "^(%s*)([-+*])%s+(.*)$"
    if not plain_indent then return end
    vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, { build_line(plain_indent, plain_marker, " ", rest) })
    return
  end
  local new = next_status(cur)
  vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, { build_line(indent, marker, new, retext(text or "", new)) })
  local _ = abs
end

--- The heading above a line, and its level.
---@param bufnr integer
---@param lnum integer 1-based line number
---@return string? header
---@return integer? level
local function heading_above(bufnr, lnum)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, lnum, false)
  local fenced = false
  local header, level
  for _, line in ipairs(lines) do
    if line:match "^%s*```" then
      fenced = not fenced
    elseif not fenced then
      local hashes, text = line:match "^(#+)%s+(.+)$"
      if hashes then
        header, level = vim.trim(text), #hashes
      end
    end
  end
  return header, level
end

--- Whether the cursor sits under the task heading of the current note.
---@param bufnr integer?
---@param lnum integer?
---@return boolean
function M.in_task_section(bufnr, lnum)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  lnum = lnum or vim.api.nvim_win_get_cursor(0)[1]
  local header = heading_above(bufnr, lnum)
  return header == M.config.section
end

--- Open a new task line below the cursor, and enter insert mode.
---
--- No key maps this. The board owns the task keys, so a note buffer keeps its
--- own keys. Call it through `:Tasks new` when you want it.
---
--- Under the task heading, the new line goes right after the last task of that
--- section, so a new task never lands in the middle of the list. Anywhere
--- else, the line goes below the cursor.
---@param opts { status?: string, anywhere?: boolean }?
---@return boolean started
function M.new_task_line(opts)
  opts = opts or {}
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype ~= "markdown" then
    vim.notify("Not a markdown note", vim.log.levels.WARN, { title = "tasks.lua" })
    return false
  end

  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Match the indent and the bullet of the task above, so a nested list keeps
  -- its shape.
  local indent, marker = "", "-"
  local insert_at = lnum

  if M.in_task_section(bufnr, lnum) and not opts.anywhere then
    -- Walk to the end of the task section, and remember the last task line.
    local last_task
    for i = lnum, #lines do
      local line = lines[i]
      if i > lnum and line:match "^#+%s" then break end
      if parse_line(line) then last_task = i end
    end
    insert_at = last_task or lnum
    if last_task then
      local task_indent, task_marker = parse_line(lines[last_task])
      indent, marker = task_indent or "", task_marker or "-"
    end
  else
    local cur_indent, cur_marker = parse_line(lines[lnum] or "")
    if cur_indent then
      indent, marker = cur_indent, cur_marker or "-"
    else
      -- A plain list item lends its shape too.
      local plain_indent, plain_marker = (lines[lnum] or ""):match "^(%s*)([-+*])%s+"
      if plain_indent then
        indent, marker = plain_indent, plain_marker
      end
    end
  end

  local line = build_line(indent, marker, opts.status or " ", "")
  vim.api.nvim_buf_set_lines(bufnr, insert_at, insert_at, false, { line })
  vim.api.nvim_win_set_cursor(0, { insert_at + 1, #line })
  vim.cmd.startinsert { bang = true }
  return true
end

--- Add a task to the daily note.
---@param text string task text
---@param opts { offset?: integer, status?: string }?
---@return boolean added
function M.add(text, opts)
  opts = opts or {}
  text = vim.trim(text or "")
  if #text == 0 then return false end
  if M.config.created_date and not text:find(CREATED_FIELD, 1, true) then text = text .. " " .. CREATED_FIELD .. " " .. today() end

  local ok, daily = pcall(require, "obsidian.daily")
  if not ok then
    vim.notify("obsidian.nvim is not available", vim.log.levels.ERROR, { title = "tasks.lua" })
    return false
  end

  local note = daily.daily { offset = opts.offset or 0 }
  if not note:exists() then note:write() end
  note:insert_text(build_line("", "-", opts.status or " ", text), {
    section = { header = M.config.section, level = 2 },
    on_section_missing = "create",
    placement = "bot",
  })
  vim.notify("Added: " .. text, vim.log.levels.INFO, { title = "tasks.lua" })
  return true
end

--- Add a task to any note.
---@param abs string absolute path of the note
---@param text string task text
---@param opts { status?: string, section?: string }?
---@return boolean added
function M.add_to(abs, text, opts)
  opts = opts or {}
  text = vim.trim(text or "")
  if #text == 0 then return false end
  if M.config.created_date and not text:find(CREATED_FIELD, 1, true) then text = text .. " " .. CREATED_FIELD .. " " .. today() end

  local ok, Note = pcall(require, "obsidian.note")
  if not ok then
    vim.notify("obsidian.nvim is not available", vim.log.levels.ERROR, { title = "tasks.lua" })
    return false
  end
  if not vim.uv.fs_stat(abs) then
    vim.notify("No such note: " .. abs, vim.log.levels.ERROR, { title = "tasks.lua" })
    return false
  end

  local note = Note.from_file(abs)
  note:insert_text(build_line("", "-", opts.status or " ", text), {
    section = { header = opts.section or M.config.section, level = 2 },
    on_section_missing = "create",
    placement = "bot",
  })
  parse_cache[abs] = nil
  vim.notify("Added: " .. text, vim.log.levels.INFO, { title = "tasks.lua" })
  return true
end

--- Set the note status field, so the board hides or shows the note.
---
--- Rewrites the field in place when it exists, else adds it to the
--- frontmatter. Adds a frontmatter block when the note has none.
---@param abs string absolute path of the note
---@param value string new value, for example "project" or "finished_project"
---@return boolean written
function M.set_note_status(abs, value)
  local field = M.config.note.field
  local lines = read_lines(abs)
  if #lines == 0 then return false end

  local pattern = "^" .. field:lower() .. ":%s*"
  local has_front = lines[1] and lines[1]:match "^%-%-%-%s*$" ~= nil

  if has_front then
    for i = 2, #lines do
      if lines[i]:match "^%-%-%-%s*$" then
        -- End of the frontmatter, and no such field. Add it above the fence.
        table.insert(lines, i, string.format("%s: %s", field, value))
        break
      end
      if lines[i]:lower():match(pattern) then
        lines[i] = string.format("%s: %s", field, value)
        break
      end
    end
  else
    table.insert(lines, 1, "---")
    table.insert(lines, 2, string.format("%s: %s", field, value))
    table.insert(lines, 3, "---")
    table.insert(lines, 4, "")
  end

  vim.fn.writefile(lines, abs)
  parse_cache[abs] = nil
  return true
end

--- Create a project note that holds tasks.
---
--- Writes the frontmatter and the headings from `config.project`, so the note
--- is ready for `M.add_to`. Never overwrites an existing note.
---@param title string note title. Becomes the file name.
---@param opts { open?: boolean, folder?: string }?
---@return string? abs absolute path of the note
function M.create_project(title, opts)
  opts = opts or {}
  title = vim.trim(title or "")
  if #title == 0 then return nil end

  local cfg = M.config.project
  local root = vault_root()
  local folder = opts.folder or cfg.folder
  local dir = vim.fs.joinpath(root, folder)

  -- A title may name a subfolder, for example "Sim/Migration Plan".
  local abs = vim.fs.joinpath(dir, title .. ".md")
  if vim.uv.fs_stat(abs) then
    vim.notify("Note already exists: " .. folder .. "/" .. title, vim.log.levels.WARN, { title = "tasks.lua" })
    if opts.open ~= false and cfg.open then vim.cmd.edit { args = { abs } } end
    return abs
  end

  local parent = vim.fs.dirname(abs)
  vim.fn.mkdir(parent, "p")

  local lines = {}

  -- Frontmatter. A value may be a function, so a date resolves at write time.
  do
    lines[#lines + 1] = "---"
    local front = vim.tbl_extend("force", {}, cfg.frontmatter or {})
    -- An open project, so the board shows the group at once.
    front[M.config.note.field] = "project"
    local keys = vim.tbl_keys(front)
    table.sort(keys)
    for _, key in ipairs(keys) do
      local value = front[key]
      if type(value) == "function" then value = value() end
      lines[#lines + 1] = string.format("%s: %s", key, tostring(value))
    end
    lines[#lines + 1] = string.format("title: %s", vim.fs.basename(title))
    lines[#lines + 1] = "---"
    lines[#lines + 1] = ""
  end

  for _, header in ipairs(cfg.sections) do
    lines[#lines + 1] = string.rep("#", cfg.level) .. " " .. header
    lines[#lines + 1] = ""
  end

  vim.fn.writefile(lines, abs)
  parse_cache[abs] = nil
  vim.notify("Created " .. folder .. "/" .. title, vim.log.levels.INFO, { title = "tasks.lua" })

  if opts.open ~= false and cfg.open then
    vim.cmd.edit { args = { abs } }
    -- Land the cursor under the task heading, ready to type.
    local head = string.rep("#", cfg.level) .. " " .. cfg.sections[1]
    for i, line in ipairs(lines) do
      if line == head then
        pcall(vim.api.nvim_win_set_cursor, 0, { math.min(i + 1, #lines), 0 })
        break
      end
    end
  end
  return abs
end

--- Ask for a title and create a project note.
---@param opts { folder?: string }?
function M.prompt_project(opts)
  vim.ui.input({ prompt = "Project note: " }, function(input)
    if input then M.create_project(input, opts) end
  end)
end

--------------------------------------------------------------------------------
-- context menus (nui)
--------------------------------------------------------------------------------

--- Open a cursor-relative pick list, and hand the choice back.
---
--- Every menu in this module has the same shape: an icon column, a name, and a
--- mark on the current value. Only the entries, the title, and what a choice
--- writes ever differ, so they all come through here.
---@param entries { value: any, icon: string?, name: string, hl: string?, current: boolean? }[]
---@param opts { title: string, width?: integer, zindex?: integer, on_pick: fun(value: any), on_cancel?: fun() }
local function context_menu(entries, opts)
  local ok, Menu = pcall(require, "nui.menu")
  if not ok then
    vim.notify("nui.nvim is not available", vim.log.levels.ERROR, { title = "tasks.lua" })
    return
  end
  local NuiLine = require "nui.line"
  local cfg = M.config.menu

  local items = {}
  for _, entry in ipairs(entries) do
    local line = NuiLine()
    line:append(entry.current and " " or "  ", cfg.hl.mark)
    line:append((entry.icon or M.config.board.marks.fallback) .. "  ", entry.hl or cfg.hl.text)
    line:append(entry.name, cfg.hl.text)
    items[#items + 1] = Menu.item(line, { value = entry.value })
  end

  local menu = Menu({
    relative = "cursor",
    position = { row = 1, col = 0 },
    zindex = (opts.zindex or 50) + 4,
    border = {
      style = cfg.border,
      text = { top = opts.title, top_align = "center" },
    },
    win_options = {
      winhighlight = string.format("Normal:%s,FloatBorder:%s,CursorLine:%s", cfg.hl.normal, cfg.hl.border, cfg.hl.cursor),
    },
  }, {
    lines = items,
    min_width = opts.width or 22,
    keymap = {
      close = { "<Esc>", "<C-c>", "q" },
      focus_next = { "j", "<Down>", "<Tab>" },
      focus_prev = { "k", "<Up>", "<S-Tab>" },
      submit = { "<CR>", "<Space>" },
    },
    on_close = function()
      if opts.on_cancel then opts.on_cancel() end
    end,
    on_submit = function(item) opts.on_pick(item.value) end,
  })
  menu:mount()
end

--- The status entries, marking `current`.
---@param current string?
---@return table[] entries
local function status_entries(current)
  local cfg = M.config
  return vim.tbl_map(function(status) return { value = status, icon = cfg.icons[status], name = cfg.names[status] or status, hl = cfg.hls[status], current = status == current } end, cfg.order)
end

--- Set the kind of the note behind a group.
---@param group Group
---@param kind NoteKind
---@return boolean written
function M.set_group_kind(group, kind)
  if not group.file then return false end
  local abs = vim.fs.joinpath(vault_root(), group.file)
  if not M.set_note_status(abs, kind) then return false end
  vim.notify(string.format("%s: %s", group.label, M.config.note.names[kind] or kind), vim.log.levels.INFO, { title = "tasks.lua" })
  return true
end

--- Show the kind list for a project, and write the choice.
---@param group Group
---@param opts { zindex?: integer, on_done?: fun(kind: NoteKind?) }?
function M.kind_menu(group, opts)
  opts = opts or {}
  local note = M.config.note

  local entries = vim.tbl_map(function(kind) return { value = kind, icon = note.icons[kind], name = note.names[kind] or kind, hl = note.hls[kind], current = kind == group.kind } end, note.project_kinds)

  context_menu(entries, {
    title = " Project ",
    width = 22,
    zindex = opts.zindex,
    on_pick = function(kind)
      local written = M.set_group_kind(group, kind)
      if opts.on_done then opts.on_done(written and kind or nil) end
    end,
    on_cancel = function()
      if opts.on_done then opts.on_done(nil) end
    end,
  })
end

--- Show the status list, and write the choice to many tasks at once.
---@param tasks Task[]
---@param opts { zindex?: integer, on_done?: fun(count: integer?) }?
function M.status_menu_many(tasks, opts)
  opts = opts or {}
  if #tasks == 0 then return end

  context_menu(status_entries(nil), {
    title = string.format(" Status · %d tasks ", #tasks),
    width = 24,
    zindex = opts.zindex,
    on_pick = function(status)
      local count = M.set_status_many(tasks, status)
      if opts.on_done then opts.on_done(count) end
    end,
    on_cancel = function()
      if opts.on_done then opts.on_done(nil) end
    end,
  })
end

--- Show the status list for one task, and write the choice.
---@param abs string absolute path of the note
---@param lnum integer 1-based line number
---@param opts { zindex?: integer, current?: string, on_done?: fun(status: string?) }?
function M.status_menu(abs, lnum, opts)
  opts = opts or {}

  context_menu(status_entries(opts.current), {
    title = M.config.menu.title,
    width = 20,
    zindex = opts.zindex,
    on_pick = function(status)
      local written = M.set_status(abs, lnum, status)
      if opts.on_done then opts.on_done(written) end
    end,
    on_cancel = function()
      if opts.on_done then opts.on_done(nil) end
    end,
  })
end

--------------------------------------------------------------------------------
-- task board (nui)
--------------------------------------------------------------------------------

---@type { mode: string|string[], lhs: string }[] global keys this module set
local global_keys = {}

---@type table? live board handle
local board = nil

--- Closes the key list. The help section defines it further down, so the
--- board needs the name in scope first.
---@type fun()
local help_close

--- Strip the Tasks plugin fields from the task text, and report them apart.
---
--- The board shows the text and a small set of signs, so a raw done-date tail
--- does not crowd the line.
---@param text string
---@return string body text with the fields removed
---@return string[] fields short labels, in display order
local function split_fields(text)
  local body, fields = text, {}

  ---@param glyph string the Tasks plugin emoji
  ---@param sign string the sign shown instead
  local function take_date(glyph, sign)
    local value = body:match(glyph .. "%s*(%d%d%d%d%-%d%d%-%d%d)")
    if value then
      body = body:gsub(glyph .. "%s*%d%d%d%d%-%d%d%-%d%d", "")
      fields[#fields + 1] = sign .. " " .. value
    end
  end

  take_date(F.done, I.done)
  take_date(F.due, I.due)
  take_date(F.scheduled, I.scheduled)
  take_date(F.start, I.start)
  take_date(F.created, I.created)

  -- A recurrence rule reads as a sign plus the rule text.
  local rule = body:match(F.repeats .. "%s*([%a%d%s]+)")
  if rule then
    body = body:gsub(F.repeats .. "%s*[%a%d%s]+", " ")
    fields[#fields + 1] = I.repeats .. " " .. vim.trim(rule)
  end

  -- Priority reads as a sign, before the dates.
  for glyph, sign in pairs(PRIORITY) do
    if body:find(glyph) then
      body = body:gsub(glyph, "")
      table.insert(fields, 1, sign)
    end
  end

  -- Tags read as a sign plus the name.
  for tag in body:gmatch "#([%w_/%-]+)" do
    fields[#fields + 1] = I.tag .. " " .. tag
  end
  body = body:gsub("#[%w_/%-]+", "")

  -- A link shows its label only, never the target.
  body = body:gsub("%[([^%]]*)%]%([^%)]*%)", "%1")
  body = body:gsub("%[%[([^%]|]*)|?[^%]]*%]%]", "%1")

  return (vim.trim(body:gsub("%s%s+", " "))), fields
end

--- Build the board lines from the group list.
---@param groups Group[]
---@return table[] lines NuiLine list
---@return table<integer, table> index row entry for each line number
---@return integer count tasks shown
local function board_lines(groups)
  local NuiLine = require "nui.line"
  local cfg = M.config
  local marks = cfg.board.marks
  local hl = cfg.board.hl
  local note = cfg.note

  local width = board and vim.api.nvim_win_get_width(board.popup.winid) or 80
  local lines, index, count = {}, {}, 0

  for i, group in ipairs(groups) do
    if i > 1 then lines[#lines + 1] = NuiLine() end

    -- A heading reads as a kind icon, the title, a rule, and a done count.
    local closed_kind = note.closed[group.kind] == true
    local icon = note.icons[group.kind] or marks.group
    local head_hl = closed_kind and hl.closed or (note.hls[group.kind] or hl.group)

    local head = NuiLine()
    head:append(" " .. icon .. "  ", closed_kind and hl.closed or hl.icon)
    head:append(group.label, head_hl)
    if group.suffix then head:append("  " .. group.suffix, hl.count) end
    if not group.exists then head:append("  " .. marks.absent, hl.count) end
    if closed_kind then head:append("  " .. (note.names[group.kind] or group.kind):lower(), hl.closed) end

    local tail = string.format(" %d/%d", group.done, #group.tasks)
    local fill = width - vim.api.nvim_strwidth(head:content()) - #tail - 3
    head:append(" " .. string.rep(marks.rule, math.max(fill, 1)), hl.rule)
    head:append(tail, hl.count)
    lines[#lines + 1] = head
    index[#lines] = { group = group }

    for _, task in ipairs(group.tasks) do
      local closed = is_closed(task.status)
      local body, fields = split_fields(task.text)

      local line = NuiLine()
      line:append(" " .. marks.indent .. " ", hl.rule)
      line:append((cfg.icons[task.status] or marks.fallback) .. "  ", cfg.hls[task.status] or hl.text)
      line:append(body, closed and hl.closed or hl.text)
      for _, field in ipairs(fields) do
        line:append("  " .. field, hl.field)
      end
      lines[#lines + 1] = line
      index[#lines] = { task = task, group = group }
      count = count + 1
    end

    if #group.tasks == 0 then
      local line = NuiLine()
      line:append(" " .. marks.indent .. "  " .. marks.empty .. "  no tasks", hl.count)
      lines[#lines + 1] = line
      index[#lines] = { group = group }
    end
  end

  if #lines == 0 then
    local line = NuiLine()
    line:append(" " .. marks.empty .. "  Nothing to do.", hl.count)
    lines = { line }
  end
  return lines, index, count
end

--- Close the board, and the key list with it.
local function board_close()
  help_close()
  if board then
    pcall(function() board.popup:unmount() end)
    board = nil
  end
end

--- Write a NuiLine list into the board buffer.
---@param lines table[] NuiLine list
local function board_paint(lines)
  if not board then return end
  local bufnr = board.popup.bufnr
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.tbl_map(function() return "" end, lines))
  for i, line in ipairs(lines) do
    line:render(bufnr, -1, i)
  end
  vim.bo[bufnr].modifiable = false
end

--- Show the mode, the group count, and the task count on the bottom border.
---@param count integer tasks shown
---@param groups integer groups shown
local function board_status(count, groups)
  if not board then return end
  local cfg = M.config.board
  local marks_task = cfg.marks.fallback
  board.popup.border:set_text("bottom", string.format(" %s %s · %s %d · %s %d ", cfg.marks.filter, board.open_only and "open" or "all", cfg.marks.group, groups, marks_task, count), "right")
end

--- Draw the board content, keeping the cursor line.
---
--- The vault read costs about 100 ms warm and more when cold, so the first
--- paint shows a placeholder and the read runs on the next tick. The window
--- appears at once, and the task list lands right after.
---@param opts { async?: boolean }?
local function board_render(opts)
  if not board then return end
  opts = opts or {}

  local function draw()
    if not board then return end
    local groups = M.groups { all = not board.open_only }
    local lines, index, count = board_lines(groups)
    board.index = index
    board_paint(lines)
    board_status(count, #groups)

    -- Put the cursor back where it was: on the same task, else on the same
    -- group heading, else on the nearest row in range.
    local row = math.max(math.min(board.row or 1, #lines), 1)
    local want_task = board.focus
    local want_group = board.focus_group
    if want_task or want_group then
      for i, entry in pairs(index) do
        if want_task and entry.task and entry.task.file == want_task.file and entry.task.lnum == want_task.lnum then
          row = i
          break
        end
        if not want_task and want_group and not entry.task and entry.group.key == want_group then
          row = i
          break
        end
      end
    end
    pcall(vim.api.nvim_win_set_cursor, board.popup.winid, { row, 0 })
  end

  if opts.async then
    local NuiLine = require "nui.line"
    local wait = NuiLine()
    wait:append("  " .. M.config.board.marks.wait .. " Reading the vault...", M.config.board.hl.count)
    board_paint { wait }
    vim.schedule(draw)
    return
  end
  draw()
end

--- The row entry under the board cursor.
---
--- An entry holds a `group`, and a `task` when the row is a task line. A
--- heading row holds the group only.
---@return table? entry
---@return integer row 1-based cursor row, 0 when the board is closed
local function board_entry()
  if not board then return nil, 0 end
  local row = vim.api.nvim_win_get_cursor(board.popup.winid)[1]
  return board.index[row], row
end

--- Remember the cursor position across a redraw.
---@param entry table?
---@param row integer
local function board_remember(entry, row)
  if not board then return end
  board.row = row
  board.focus = entry and entry.task or nil
  board.focus_group = entry and entry.group and entry.group.key or nil
end

--- Make sure the note behind a group exists, and return its path.
---
--- A pinned daily group may have no file yet. The note is written the moment
--- you add a task to it, or open it.
---@param group Group
---@return string? abs
local function ensure_group_note(group)
  local root = vault_root()
  if group.file and vim.uv.fs_stat(vim.fs.joinpath(root, group.file)) then return vim.fs.joinpath(root, group.file) end

  if group.kind == "daily" then
    local ok, daily = pcall(require, "obsidian.daily")
    if not ok then
      vim.notify("obsidian.nvim is not available", vim.log.levels.ERROR, { title = "tasks.lua" })
      return nil
    end
    local note = daily.daily { offset = group.offset or 0 }
    if not note:exists() then note:write() end
    local abs = tostring(note.path)
    parse_cache[abs] = nil
    return abs
  end

  return group.file and vim.fs.joinpath(root, group.file) or nil
end

--- Step the cursor to the next or the previous row that holds a task.
---@param step 1|-1
local function board_jump(step)
  if not board then return end
  local row = vim.api.nvim_win_get_cursor(board.popup.winid)[1]
  local last = vim.api.nvim_buf_line_count(board.popup.bufnr)
  for i = row + step, step > 0 and last or 1, step do
    if board.index[i] then
      vim.api.nvim_win_set_cursor(board.popup.winid, { i, 0 })
      return
    end
  end
end

--- Open the task board. Toggles when already open.
---@param opts { open_only?: boolean }?
function M.board_toggle(opts)
  if board then
    board_close()
    return
  end
  opts = opts or {}

  local ok, Popup = pcall(require, "nui.popup")
  if not ok then
    vim.notify("nui.nvim is not available", vim.log.levels.ERROR, { title = "tasks.lua" })
    return
  end
  local cfg = M.config.board

  local popup = Popup {
    enter = true,
    focusable = true,
    zindex = cfg.zindex,
    border = {
      style = cfg.border,
      text = { top = cfg.title, top_align = "center" },
    },
    position = "50%",
    size = cfg.size,
    buf_options = { modifiable = false, filetype = "obsidian-tasks" },
    win_options = {
      winhighlight = string.format("Normal:%s,FloatBorder:%s,CursorLine:%s", cfg.hl.normal, cfg.hl.border, cfg.hl.cursor),
      cursorline = true,
      wrap = false,
      number = false,
      relativenumber = false,
      signcolumn = "no",
    },
  }

  board = {
    popup = popup,
    open_only = opts.open_only ~= false,
    index = {},
    row = 1,
  }

  popup:mount()
  popup:on({ "BufLeave", "WinClosed" }, function() board_close() end, { once = true })

  local keys = M.config.board.keys
  ---@param lhs string|string[]
  ---@param fn function
  ---@param mode string? map mode. Defaults to normal.
  local function map(lhs, fn, mode)
    for _, key in ipairs(type(lhs) == "table" and lhs or { lhs }) do
      popup:map(mode or "n", key, fn, { noremap = true, nowait = true })
    end
  end

  --- The tasks in the visual selection.
  ---
  --- The `<` and `>` marks only settle after visual mode ends, so read the
  --- live range instead: `v` holds the anchor and the cursor holds the other
  --- end. A heading row in the range contributes the tasks of its group.
  ---@return Task[] tasks
  ---@return integer row the first row of the range
  local function selected_tasks()
    if not board then return {}, 1 end
    local anchor = vim.fn.getpos("v")[2]
    local cursor = vim.api.nvim_win_get_cursor(board.popup.winid)[1]
    local first, last = math.min(anchor, cursor), math.max(anchor, cursor)

    -- Leave visual mode, so the board redraw lands in normal mode.
    vim.api.nvim_feedkeys(vim.keycode "<Esc>", "n", false)

    local tasks, seen = {}, {}
    for row = first, last do
      local entry = board.index[row]
      if entry then
        -- A heading brings its whole group, minus any task the range already
        -- holds on its own row.
        local group_tasks = entry.task and { entry.task } or entry.group.tasks
        for _, task in ipairs(group_tasks) do
          local id = task.file .. ":" .. task.lnum
          if not seen[id] then
            seen[id] = true
            tasks[#tasks + 1] = task
          end
        end
      end
    end
    return tasks, first
  end

  -- Tab cycles the status of the task under the cursor. On a heading, it
  -- cycles every task of the group.
  map(keys.toggle, function()
    local entry, row = board_entry()
    if not entry then return end
    board_remember(entry, row)
    if entry.task then
      M.set_status(vim.fs.joinpath(vault_root(), entry.task.file), entry.task.lnum)
    elseif #entry.group.tasks > 0 then
      M.set_status_many(entry.group.tasks)
    end
    board_render()
  end)

  -- Enter on a task opens the status menu. Enter on a heading opens the kind
  -- menu for a project, or creates the note for a pinned daily group.
  map(keys.menu, function()
    local entry, row = board_entry()
    if not entry then return end
    board_remember(entry, row)

    if entry.task then
      M.status_menu(vim.fs.joinpath(vault_root(), entry.task.file), entry.task.lnum, {
        zindex = cfg.zindex,
        current = entry.task.status,
        on_done = function(status)
          if status then board_render() end
        end,
      })
      return
    end

    local group = entry.group
    if group.kind == "daily" then
      -- A daily note has no kind to choose. Make sure the note exists, then
      -- add a task to it.
      local abs = ensure_group_note(group)
      if not abs then return end
      vim.ui.input({ prompt = "Task: " }, function(input)
        if input then
          M.add_to(abs, input)
          board_render()
        end
      end)
      return
    end

    M.kind_menu(group, {
      zindex = cfg.zindex,
      on_done = function(kind)
        if kind then board_render() end
      end,
    })
  end)

  -- The same two keys work on a visual-line range, for a bulk change.
  map(keys.toggle, function()
    local tasks, row = selected_tasks()
    if #tasks == 0 then return end
    board.row, board.focus = row, tasks[1]
    M.set_status_many(tasks)
    board_render()
  end, "x")

  map(keys.menu, function()
    local tasks, row = selected_tasks()
    if #tasks == 0 then return end
    board.row, board.focus = row, tasks[1]
    M.status_menu_many(tasks, {
      zindex = cfg.zindex,
      on_done = function(count)
        if count and count > 0 then board_render() end
      end,
    })
  end, "x")

  -- Open the note behind the row. A pinned daily note is created first.
  map(keys.open, function()
    local entry = board_entry()
    if not entry then return end
    local abs = ensure_group_note(entry.group)
    if not abs then return end
    local lnum = entry.task and entry.task.lnum or nil
    board_close()
    vim.cmd.edit { args = { abs } }
    if lnum then pcall(vim.api.nvim_win_set_cursor, 0, { lnum, 0 }) end
  end)

  -- Add a task to the group under the cursor, project or daily note. On a
  -- task row, the task joins the same group.
  map(keys.add, function()
    local entry, row = board_entry()
    if not entry then
      -- An empty board still adds to today.
      vim.ui.input({ prompt = "Task (today): " }, function(input)
        if input then
          M.add(input)
          board_render()
        end
      end)
      return
    end

    board_remember(entry, row)
    local group = entry.group
    local abs = ensure_group_note(group)
    if not abs then return end

    vim.ui.input({ prompt = string.format("Task (%s): ", group.label) }, function(input)
      if input then
        M.add_to(abs, input)
        board_render()
      end
    end)
  end)

  -- Create a project note. The board gains the group at once, and the note
  -- stays closed.
  map(keys.project, function()
    vim.ui.input({ prompt = "Project name: " }, function(input)
      if not input or vim.trim(input) == "" then return end
      local abs = M.create_project(input, { open = false })
      if abs then
        board.focus, board.focus_group = nil, abs:sub(#vault_root() + 2)
        board_render()
      end
    end)
  end)

  -- Step the kind of the project under the cursor.
  map(keys.note_kind, function()
    local entry, row = board_entry()
    if not entry or entry.group.kind == "daily" then return end
    board_remember(entry, row)
    local kinds = M.config.note.project_kinds
    local cur = entry.group.kind
    local next_kind = kinds[1]
    for i, k in ipairs(kinds) do
      if k == cur then
        next_kind = kinds[i % #kinds + 1]
        break
      end
    end
    if M.set_group_kind(entry.group, next_kind) then board_render() end
  end)

  -- Jump to the Today group.
  map(keys.group, function()
    for i, entry in pairs(board.index) do
      if not entry.task and entry.group.suffix == "Today" then
        vim.api.nvim_win_set_cursor(board.popup.winid, { i, 0 })
        return
      end
    end
  end)

  map(keys.filter, function()
    board.open_only = not board.open_only
    board_render()
  end)

  map(keys.search, function()
    local open_only = board.open_only
    board_close()
    M.picker { open_only = open_only }
  end)

  map(keys.refresh, function() board_render() end)
  map(keys.next, function() board_jump(1) end)
  map(keys.prev, function() board_jump(-1) end)
  map(keys.help, function() M.help_toggle(cfg.zindex, "board") end)

  -- Escape or `q` closes the key list first, so one press never drops the
  -- board out from under an open popup.
  map(keys.close, function()
    if M.help_open() then
      help_close()
      return
    end
    board_close()
  end)

  -- Show the window at once, then fill it on the next tick.
  board_render { async = true }
  vim.schedule(function() board_jump(1) end)
end

--------------------------------------------------------------------------------
-- help popup (nui)
--------------------------------------------------------------------------------

--- The key list, in display order.
---@param context "board"|"picker"
---@return { group: string, binds: string[][] }[] sections
local function help_sections(context)
  local order = table.concat(vim.tbl_map(function(s) return "[" .. s .. "]" end, M.config.order), " → ")

  if context == "board" then
    local keys = M.config.board.keys
    return {
      {
        group = "On a task",
        binds = {
          { key_label(keys.toggle), "cycle status: " .. order },
          { key_label(keys.menu), "open the status menu" },
          { key_label(keys.add), "add a task to the same group" },
          { key_label(keys.open), "open the note at the task" },
        },
      },
      {
        group = "On a heading",
        binds = {
          { key_label(keys.menu), "project: pick the kind. daily: add a task" },
          { key_label(keys.toggle), "cycle every task in the group" },
          { key_label(keys.add), "add a task to the group" },
          { key_label(keys.note_kind), "step the project kind" },
          { key_label(keys.open), "open the note, creating it when absent" },
        },
      },
      {
        group = "Many tasks",
        binds = {
          { "V", "start a line selection" },
          { key_label(keys.toggle), "cycle every task in the selection" },
          { key_label(keys.menu), "set one status for the selection" },
        },
      },
      {
        group = "Board",
        binds = {
          { key_label(keys.project), "create a project, without opening it" },
          { key_label(keys.filter), "show open work, or every group" },
          { key_label(keys.group), "jump to Today" },
          { key_label(keys.search), "search with fzf" },
          { key_label(keys.refresh), "read the vault again" },
        },
      },
      {
        group = "Move",
        binds = {
          { key_label(keys.next) .. " / " .. key_label(keys.prev), "next task, previous task" },
          { key_label(keys.help), "close this popup" },
          { key_label(keys.close), "close the board" },
        },
      },
    }
  end

  local keys = M.config.keys
  return {
    {
      group = "Task",
      binds = {
        { key_label(keys.done), "mark done, stamp the date" },
        { key_label(keys.cycle), "cycle status: " .. order },
        { key_label(keys.add), "add the query as a task today" },
      },
    },
    {
      group = "Open",
      binds = {
        { "enter", "open the task line" },
        { "ctrl-s", "open in a split" },
        { "ctrl-v", "open in a vertical split" },
        { "ctrl-t", "open in a tab" },
        { "alt-q", "send the selection to the quickfix list" },
      },
    },
    {
      group = "Window",
      binds = {
        { "tab", "select, for a multiple-task action" },
        { "ctrl-f / ctrl-b", "scroll the list" },
        { "shift-up / shift-down", "scroll the preview" },
        { "F4", "toggle the preview" },
        { key_label(keys.help), "close this popup" },
        { "esc", "quit" },
      },
    },
  }
end

---@type table? live popup handle
local help_popup = nil

--- Whether the key list is open.
---@return boolean open
function M.help_open() return help_popup ~= nil end

--- Close the key list.
function M.help_close() help_close() end

--- Close the help popup. Assigns the name declared above the board.
function help_close()
  if help_popup then
    if help_popup.__restore then pcall(help_popup.__restore) end
    pcall(function() help_popup:unmount() end)
    help_popup = nil
  end
end

--- Show the key list in a centered nui popup. Toggles when already open.
---@param zindex integer? stack the popup above the caller window
---@param context "board"|"picker"? which key list to show. Defaults to picker.
function M.help_toggle(zindex, context)
  if help_popup then
    help_close()
    return
  end

  local ok, Popup = pcall(require, "nui.popup")
  if not ok then
    vim.notify("nui.nvim is not available", vim.log.levels.ERROR, { title = "tasks.lua" })
    return
  end
  local NuiLine = require "nui.line"

  local cfg = M.config.help
  local sections = help_sections(context or "picker")

  -- Size the key column to the widest key.
  local key_width = 0
  for _, section in ipairs(sections) do
    for _, bind in ipairs(section.binds) do
      key_width = math.max(key_width, vim.api.nvim_strwidth(bind[1]))
    end
  end

  -- Build the lines, and measure the widest one.
  local lines, width = {}, vim.api.nvim_strwidth(cfg.title)
  for i, section in ipairs(sections) do
    if i > 1 then lines[#lines + 1] = NuiLine() end
    local head = NuiLine()
    head:append(section.group, cfg.hl.group)
    lines[#lines + 1] = head
    for _, bind in ipairs(section.binds) do
      local line = NuiLine()
      line:append("  " .. string.format("%-" .. key_width .. "s", bind[1]), cfg.hl.key)
      line:append("  " .. bind[2], cfg.hl.desc)
      lines[#lines + 1] = line
      width = math.max(width, vim.api.nvim_strwidth(line:content()))
    end
  end

  help_popup = Popup {
    enter = false,
    focusable = false,
    zindex = (zindex or 50) + 6,
    border = {
      style = cfg.border,
      text = { top = cfg.title, top_align = "center" },
    },
    position = "50%",
    size = { width = math.min(width + 4, vim.o.columns - 4), height = math.min(#lines, vim.o.lines - 6) },
    win_options = {
      winhighlight = string.format("Normal:%s,FloatBorder:%s", cfg.hl.normal, cfg.hl.border),
      wrap = false,
    },
  }
  help_popup:mount()
  for i, line in ipairs(lines) do
    line:render(help_popup.bufnr, -1, i)
  end

  -- The popup never takes focus, so a map on its own buffer would not fire.
  -- Bind escape on the calling buffer, and remove the bind on close.
  local caller = vim.api.nvim_get_current_buf()
  local mode = context == "picker" and "t" or "n"
  local had_esc = false
  for _, m in ipairs(vim.api.nvim_buf_get_keymap(caller, mode)) do
    if m.lhs == "<Esc>" then had_esc = true end
  end

  vim.keymap.set(mode, "<Esc>", function() help_close() end, { buffer = caller, nowait = true, desc = "Tasks: close the key list" })

  help_popup.__restore = function()
    if not vim.api.nvim_buf_is_valid(caller) then return end
    pcall(vim.keymap.del, mode, "<Esc>", { buffer = caller })
    -- The fzf window binds escape itself, so put that bind back.
    if had_esc and mode == "t" then pcall(vim.keymap.set, mode, "<Esc>", "<Esc>", { buffer = caller, nowait = true }) end
  end
end

--------------------------------------------------------------------------------
-- fzf-lua picker
--------------------------------------------------------------------------------

--- Build the fzf entry for a task.
---
--- The entry starts with `path:line:col:`, because the file actions and the
--- previewer read those fields. `--with-nth` hides them, so the list shows the
--- note title and the task text only.
---@param task Task
---@param utils table fzf-lua utils
---@return string entry
local function make_entry(task, utils)
  local cfg = M.config
  local icon = cfg.icons[task.status] or "󰄱"
  local hl = cfg.hls[task.status]
  if hl then icon = utils.ansi_from_hl(hl, icon) end
  local text = task.text
  if is_closed(task.status) then text = utils.ansi_codes.grey(text) end
  return string.format("%s:%d:%d:%s %s %s %s", task.file, task.lnum, 1, icon, utils.ansi_from_hl(cfg.picker_hl.title, task.title), utils.ansi_from_hl(cfg.picker_hl.separator, cfg.separator), text)
end

--- Resolve a picker selection to a file path and line number.
---@param selected string
---@param opts table
---@return string? abs
---@return integer? lnum
local function selection_to_task(selected, opts)
  local path = require "fzf-lua.path"
  local entry = path.entry_to_file(selected, opts)
  if not entry or not entry.path or not entry.line then return nil, nil end
  local abs = entry.path
  if not path.is_absolute(abs) then abs = vim.fs.joinpath(opts.cwd or vault_root(), abs) end
  return abs, tonumber(entry.line)
end

--- Search tasks with fzf-lua.
---@param opts table? picker options. `open_only = true` hides closed tasks.
function M.picker(opts)
  local core = require "fzf-lua.core"
  local utils = require "fzf-lua.utils"
  local config = require "fzf-lua.config"

  local keys = M.config.keys
  local open_only = opts and opts.open_only
  opts = vim.tbl_deep_extend("keep", opts or {}, {
    cwd = vault_root(),
    prompt = open_only and "OpenTasks❯ " or "Tasks❯ ",
    file_icons = false,
    git_icons = false,
    color_icons = false,
    fzf_opts = {
      ["--multi"] = true,
      ["--delimiter"] = "[:]",
      -- Hide the path, the line, and the column. They stay in the entry, so
      -- the actions and the previewer keep working.
      ["--with-nth"] = "4..",
      ["--wrap"] = true,
    },
    -- The help keys open the popup below, not the fzf-lua help strip.
    keymap = { builtin = help_keymap(keys.help) },
    header_prefix = string.format(":: <%s> for keys |", key_label(keys.help)),
    _cached_hls = { "path_colnr", "path_linenr" },
  })
  -- Own globals table, so the picker gets the file actions and the file
  -- previewer without the grep-only binds (toggle ignore, regex switch).
  opts = config.normalize_opts(opts, {
    previewer = require("fzf-lua.defaults")._default_previewer_fn,
    _actions = function() return config.globals.actions.files end,
    _headers = { "actions", "cwd" },
    __resume_key = "obsidian_tasks",
  })
  if not opts then return end
  opts.cwd = vault_root()

  -- Map the help key in the fzf terminal buffer, and drop the popup when the
  -- picker window closes.
  local zindex = (opts.winopts and opts.winopts.zindex) or 50
  local prev_on_create = opts.winopts and opts.winopts.on_create
  local prev_on_close = opts.winopts and opts.winopts.on_close
  opts.winopts = vim.tbl_extend("force", opts.winopts or {}, {
    on_create = function(e)
      for _, key in ipairs(help_keys(keys.help)) do
        vim.keymap.set("t", key, function() M.help_toggle(zindex, "picker") end, { buffer = e.bufnr, nowait = true, desc = "Tasks: keys" })
      end
      if prev_on_create then prev_on_create(e) end
    end,
    on_close = function()
      help_close()
      if prev_on_close then prev_on_close() end
    end,
  })

  ---@param status string? new status. Cycles the status when nil.
  ---@param label string header and help label
  ---@return table action
  local function status_action(status, label)
    return {
      fn = function(selected)
        for _, sel in ipairs(selected) do
          local abs, lnum = selection_to_task(sel, opts)
          if abs and lnum then M.set_status(abs, lnum, status) end
        end
      end,
      reload = true,
      desc = label,
      header = label,
    }
  end

  opts.actions = vim.tbl_extend("force", opts.actions or {}, {
    -- The contents come from Lua, not from a shell command, so the
    -- file-picker toggles do not apply here.
    ["alt-i"] = false,
    ["alt-h"] = false,
    ["alt-f"] = false,
    [keys.done] = status_action(M.config.done, "complete"),
    [keys.cycle] = status_action(nil, "cycle status"),
    [keys.add] = {
      fn = function(selected) M.add(selected and selected[1] or "") end,
      field_index = "{q}",
      reload = true,
      desc = "add task from query",
      header = "add query as task",
    },
  })

  local contents = function(fzf_cb)
    coroutine.wrap(function()
      local co = coroutine.running()
      vim.schedule(function()
        for _, task in ipairs(M.collect { open_only = open_only }) do
          fzf_cb(make_entry(task, utils))
        end
        coroutine.resume(co)
      end)
      coroutine.yield()
      fzf_cb(nil)
    end)()
  end

  opts = core.set_fzf_field_index(opts, "{2}", "{1}")
  return core.fzf_exec(contents, opts)
end

--- Search open tasks only.
---@param opts table?
function M.picker_open(opts) return M.picker(vim.tbl_extend("force", opts or {}, { open_only = true })) end

--- Ask for a task and add it to a daily note.
---@param offset integer? day offset, for example 1 for tomorrow
function M.prompt_add(offset)
  vim.ui.input({ prompt = "Task: " }, function(input)
    if input then M.add(input, { offset = offset }) end
  end)
end

--------------------------------------------------------------------------------
-- setup
--------------------------------------------------------------------------------

--- Close every window this module owns, and drop its keys and commands.
---
--- A reload needs this, because the board and the popup state live in the old
--- module table. `M.reload` calls it for you.
function M.teardown()
  pcall(help_close)
  pcall(board_close)
  M.invalidate()

  pcall(vim.api.nvim_del_user_command, "Tasks")
  pcall(vim.api.nvim_del_augroup_by_name, "tasks-markdown")

  -- Drop exactly the keys this module set. Scanning every global map by
  -- description also worked, but this needs no guesswork.
  for _, m in ipairs(global_keys) do
    pcall(vim.keymap.del, m.mode, m.lhs)
  end
  global_keys = {}
end

--- Reload the module from disk, and set it up again.
---
--- Closes the board and the key list first, clears the `package.loaded` entry,
--- then calls `setup` on the fresh copy. Use it while editing this file.
---@param cfg TasksConfig? overrides for the fresh copy
---@return table module the reloaded module
function M.reload(cfg)
  M.teardown()
  package.loaded[MODULE] = nil
  local fresh = require(MODULE)
  fresh.setup(cfg)
  vim.notify("Reloaded " .. MODULE, vim.log.levels.INFO, { title = "tasks.lua" })
  return fresh
end

---@param cfg TasksConfig? overrides merged into `M.config`
function M.setup(cfg)
  M.config = vim.tbl_deep_extend("force", M.config, cfg or {})

  local ok_fzf, fzf = pcall(require, "fzf-lua")
  if ok_fzf then
    fzf.register_extension("obsidian_tasks", M.picker, {}, true)
    fzf.register_extension("obsidian_tasks_open", M.picker_open, {}, true)
  end

  vim.api.nvim_create_user_command("Tasks", function(data)
    local args = vim.split(vim.trim(data.args), " ", { trimempty = true })
    local sub = table.remove(args, 1) or "board"
    local rest = table.concat(args, " ")
    if sub == "add" then
      if #rest > 0 then
        M.add(rest)
      else
        M.prompt_add()
      end
    elseif sub == "board" then
      M.board_toggle()
    elseif sub == "all" then
      M.picker()
    elseif sub == "open" then
      M.picker_open()
    elseif sub == "toggle" then
      M.toggle_current()
    elseif sub == "new" then
      M.new_task_line()
    elseif sub == "reload" then
      M.reload()
    elseif sub == "project" then
      if #rest > 0 then
        M.create_project(rest)
      else
        M.prompt_project()
      end
    else
      vim.notify("Unknown subcommand: " .. sub, vim.log.levels.ERROR, { title = "tasks.lua" })
    end
  end, {
    nargs = "*",
    desc = "Obsidian tasks",
    complete = function(arg)
      return vim.tbl_filter(function(x) return x:find(arg, 1, true) == 1 end, { "add", "all", "board", "new", "open", "project", "reload", "toggle" })
    end,
  })

  --- Set a global key, and remember it for `M.teardown`.
  ---@param mode string|string[]
  ---@param lhs string
  ---@param fn function
  ---@param desc string
  local function map(mode, lhs, fn, desc)
    global_keys[#global_keys + 1] = { mode = mode, lhs = lhs }
    vim.keymap.set(mode, lhs, fn, { noremap = true, silent = true, desc = desc })
  end

  -- Alt plus `n` opens the board, the way the alt keys open the terminals.
  map({ "n", "x", "t" }, M.config.board.open_key, function() M.board_toggle() end, "Tasks: board")
  map("n", "<leader>ka", function() M.prompt_add() end, "Tasks: Add to today")
  map("n", "<leader>kA", function() M.prompt_add(1) end, "Tasks: Add to tomorrow")
  map("n", "<leader>kk", function() M.board_toggle() end, "Tasks: Board")
  map("n", "<leader>ks", function() M.picker_open() end, "Tasks: Search open")
  map("n", "<leader>kf", function() M.picker() end, "Tasks: Search all")
  map("n", "<leader>kp", function() M.prompt_project() end, "Tasks: New project note")
end

return M
