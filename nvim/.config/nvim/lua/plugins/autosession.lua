return {
  "rmagatti/auto-session",
  lazy = false,

  ---enables autocomplete for opts
  ---@module "auto-session"
  ---@type AutoSession.Config
  opts = {
    suppressed_dirs = {
      "~/",
      "~/Projects",
      "~/Downloads",
      "/",
      "~/Repositories/",
      "~/repositories",
    },
    -- log_level = 'debug',
    pre_save_cmds = { "tabdo Neotree close" },
    post_restore_cmds = { "Neotree" },
  },
}
