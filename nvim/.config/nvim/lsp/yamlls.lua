return {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
  root_dir = function(fname) return vim.fs.dirname(vim.fs.find(".git", { path = fname, upward = true })[1]) end,
  settings = {
    yaml = {
      schemas = {
        ["https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json"] = ".gitlab-ci.yml",
      },
      customTags = {
        "!reference sequence",
      },
    },
  },
  single_file_support = true,
}
