# dotfiles

Configuration for zsh, Neovim, and the tools around them. One script
installs everything into `$HOME`. No root access is needed.

```sh
git clone --recurse-submodules https://github.com/dominicfmazza/dotfiles ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

## What the bootstrap does

`bootstrap.sh` installs mise into `~/.local/bin/mise`, then runs a mise
task. After the first run, `mise run <command>` does the same thing.

The `install` command runs these steps in order:

1. `preflight`: checks the host requirements and stops on a missing one.
2. `submodules`: checks out antidote, or clones it when git cannot.
3. `hooks`: installs the secret scan as a `pre-commit` hook.
4. `prune`: repairs a host that has an older install of this repo.
5. `link`: links every package into `$HOME`, the way GNU stow did.
6. `seed`: copies the host files, such as `~/.env.json`, one time.
7. `tools`: installs the tools of the profile from `mise.lock`.
8. `neovim`: syncs the Neovim plugins from the lock file.
9. `wm`: installs AeroSpace and simple-bar on macOS.
10. `shell`: warms the zsh plugin cache and makes zsh the shell.

Run it again at any time. Every step is idempotent.

## Change what gets installed

Each change is an edit to a data file. No script needs a change.

| To change | Edit |
| --- | --- |
| A config package, or its platforms | a `link` row in `install/manifest.conf` |
| A file that a host copies one time | a `seed` row in `install/manifest.conf` |
| A tool | a profile file in `mise/.config/mise/profiles/` |
| The files in a profile | `profile_*` in `mise.toml` |
| The steps of a command | `steps_*` in `mise.toml` |
| A custom step | a script in `install/tasks/step/` |

After a tool change, run `mise run lock` and commit `mise.lock`.

A step is a small shell script. Its `#MISE description=` line names it in
`mise tasks`. It sources `install/env.sh` and can use the helpers
in `install/lib.sh`. `mise run step:<name>` runs one step alone.

## Host requirements

The host must supply these. A rootless install cannot create them.

| Requirement | Floor | Why |
| --- | --- | --- |
| POSIX shell, coreutils | any | The bootstrap runtime. |
| `git` | 2.7 | Submodules, plugins, antidote. |
| `curl` or `wget` | any | The mise installer and every download. |
| `tar`, `gzip`, `xz`, `unzip` | any | Archive extraction. |
| `zsh` | 5.8 | The interactive shell. mise has no zsh package. |
| `clang` | any | tree-sitter, the treesitter parsers, and `cargo:` crates. |
| Writable `$HOME` | — | Every install target. |
| Network to github.com and mise.jdx.dev | — | Tool downloads. |
| A true-color terminal | — | `termguicolors` and the prompt. |
| A Nerd Font on the terminal host | — | Glyphs in the prompt, Neovim, and yazi. |

The `full` profile installs Hack Nerd Font with mise. A mise hook copies
it into the user font directory, so no root is needed. On WSL the terminal
runs on Windows. Install the font on the Windows host in that case.

mise supplies everything else: node, go, rust, python, uv, zig, cmake, fzf,
fd, ripgrep, bat, jq, eza, zoxide, skim, lazygit, yazi, Neovim, every
language server, and every formatter.

The host must have clang. tree-sitter, the treesitter parsers, and the
`cargo:` crates build with it. The preflight step stops when clang is
missing. On macOS, `xcode-select --install` supplies clang.

On a RHEL 9 host, `dnf install zsh git tar gzip xz unzip clang` covers
every requirement. Ask the host owner for that one command.

## Commands

```sh
./bootstrap.sh                    # link and install everything
./bootstrap.sh --profile core     # a smaller tool set
./bootstrap.sh link               # link only, no tool install
./bootstrap.sh doctor             # check an existing install
./bootstrap.sh scan               # check the repo for a leaked credential
./bootstrap.sh uninstall          # remove every link this repo owns
./bootstrap.sh install --help     # every flag
```

After the first install, `mise run install`, `mise run doctor`, and the
others do the same thing. `mise tasks` lists them.

### Profiles

The mise tool list is in `mise/.config/mise/profiles/`. A profile decides
which files the bootstrap links into `~/.config/mise/conf.d/`. The
`profile_*` values in `mise.toml` set the files of each profile.

| Profile | Files | Use for |
| --- | --- | --- |
| `core` | `00-core` | A shell on a jump host. |
| `lang` | `+ 10-lang` | A build box. |
| `editor` | `+ 20-editor` | A workstation with no display. |
| `full` | `+ 25-desktop` | A workstation. The default. Adds kitty and the font. |
| `work` | `+ 30-work` | An employer host: aws, terraform, glab, jira. |

### The lock file

`mise/.config/mise/mise.lock` holds the exact URL and checksum of each
tool, for every profile and platform. The bootstrap links it into
`~/.config/mise`, and the `tools` step runs `mise install --locked`. A
host then gets the same files as every other host, with no release lookup.

After a pin change, run `mise run lock` and commit the file. A tool that
is not in the lock file fails with `--locked`.

### Conflicts

A file the host already has blocks a link. The bootstrap reports it and
moves on. Pick a policy to resolve it:

| Flag | Action |
| --- | --- |
| `--backup` | Move the file to `<name>.bak.<timestamp>`, then link. |
| `--adopt` | Move the file into the repo, then link. |
| `--force` | Delete the file, then link. |

## Host-specific values

These files hold anything specific to one machine. None is in git.

| File | Holds |
| --- | --- |
| `~/.config/environments/hosts.sh` | Paths and identities. zsh sources it at login. |
| `~/.env.json` | Tokens. mise loads it into the environment. |
| `~/.pi/agent/settings.json` | pi settings. pi rewrites it, so it is a copy. |
| `~/.pi/agent/models.json` | Custom LLM providers and their endpoints. |
| `~/.pi/agent/auth.json` | pi credentials. Run `pi` and use `/login`. |
| `~/.config/mcp/mcp.json` | MCP server endpoints. |

The bootstrap seeds each one from `install/templates/`, and never overwrites
an existing file.

## Vault sync over SSH

`vault-sync` keeps a copy of the Obsidian vault on a remote host. It uses
Mutagen over SSH, so the remote host needs only SSH. Edits on the remote
host come back to the local vault, and OneDrive uploads them.

1. Add an alias for the remote host to `~/.ssh/config`.
2. Add the alias to `VAULT_SYNC_HOSTS` in `hosts.sh`.
3. Connect with `ssh <alias>`.

The `ssh` function in `.aliases` starts the sync before it connects. It
also sets `OBSIDIAN_VAULT_ROOT` on the remote host through the kitty kitten.
The sync continues after you disconnect. Run `vault-sync pause <alias>` to
stop it. Run `vault-sync status` to see conflicts.

Set the vault folder to "Always keep on this device" in OneDrive. Mutagen
cannot read an online-only placeholder file.

Add `GITHUB_TOKEN` to `~/.env.json` on a shared network. The GitHub API
allows 60 calls per hour per address, and mise reads release lists from it.

## Secrets

This repo is public. `install/scan-secrets.sh` blocks a commit that adds a
token, an internal hostname, or a pi runtime file. The bootstrap installs it
as a `pre-commit` hook, and `doctor` runs it too.

```sh
./bootstrap.sh scan          # scan by hand
```

The scan looks for GitHub, GitLab, OpenAI, Anthropic, AWS, Slack, and pi
provider tokens, private key blocks, a literal value in an `apiKey` field, an
internal hostname, and any pi file that carries state. An `$ENV_VAR` or a
`!command` reference is a safe value and never triggers it.

## A network home

On a host where `$HOME` is NFS, such as an Amazon RES desktop, a tool that
locks a cache file fails. NFS without a lock daemon rejects `flock`, and the
kernel returns `EBADF`, which a tool reports as
`Bad file descriptor (os error 9)`.

`~/.zshenv` detects that case and splits the two kinds of data:

| Data | Location | Reason |
| --- | --- | --- |
| mise tool installs, 3.4 G | `$HOME` | Large. Must survive a reboot. |
| Caches: mise, npm, uv, pip, go | `/var/tmp/$USER-cache` | Locks work. Rebuildable. |

Detection uses the filesystem name first, then a real `flock` attempt for an
unusual filesystem. The probe result is cached against the boot id, so only
the first shell after a reboot pays for it.

RES replaces the instance often, so the local cache is empty after each boot.
That costs nothing: every tool carries an exact version, so mise resolves from
disk and makes no release API call. `latest` would cost one HTTP call per tool
per boot.

To move a pin forward:

```sh
mise outdated
mise upgrade --bump
```

Set `DOTFILES_CACHE_ROOT` to override the cache location.

## Tests

The tests run the bootstrap in a container as a user with no root. The
default image is RHEL 9 (UBI), which matches the target fleet.

```sh
install/test/run.sh link     # link layer only. Fast.
install/test/run.sh nfs      # a network home: cache redirect, zsh order.
install/test/run.sh upgrade  # an older install, then an upgrade to HEAD.
install/test/run.sh full     # every tool, Neovim, and the plugins. Slow.
install/test/run.sh all      # every case in order.
install/test/run.sh shell    # a shell in a fresh container.
```

The `upgrade` case matters most after a layout change. It installs an older
ref, upgrades to HEAD, and checks that no stale link survives. A dangling
`~/.config/zsh` makes zsh run its new-user configurator instead of giving a
prompt, because an older session still exports `ZDOTDIR` and finds no startup
file there.

Set `GITHUB_TOKEN` before a full run. Set `DOTFILES_TEST_BASE` to test
another distribution, for example `ubuntu:24.04`.

## Terminals

Three terminal configs share one look: the vague palette and Hack Nerd Font.

| Terminal | Config | Platforms |
| --- | --- | --- |
| kitty | `~/.config/kitty/kitty.conf` | Linux, macOS |
| rio | `~/.config/rio` (Linux), Windows profile | Linux, WSL, Windows |
| wezterm | `~/.wezterm.lua` | Linux, WSL, macOS |

The kitty config hides the tab bar for a single tab, uses a block cursor, and
opens a 120x28 window. This matches the rio and wezterm setup.

On Linux and macOS the `full` profile installs kitty with mise, from the
kitty release archive. No root is needed. On WSL, install kitty on the
Windows host. An older install put kitty in `~/.local/kitty.app`. The
bootstrap removes its links. Delete the directory when kitty works.

## Windows

`komorebi`, `glazewm`, and `rio/windows` target Windows. On WSL, the
bootstrap links them into the Windows user profile. Run it from WSL with
developer mode on, or run `tools/symlinkwsl.ps1` from PowerShell.

## Window management

The tiling setup matches across platforms. On Windows, komorebi tiles and
whkd binds the keys. On macOS, AeroSpace does both.

| Platform | Tiler | Keys | Config |
| --- | --- | --- | --- |
| Windows, WSL | komorebi | whkd | `komorebi/` |
| macOS | AeroSpace | AeroSpace | `~/.config/aerospace/aerospace.toml` |

On macOS the bootstrap installs AeroSpace with Homebrew
(`brew install --cask nikitabobko/tap/aerospace`). Homebrew must be present
first. The bootstrap never installs Homebrew, because Homebrew needs a
privileged step, and this repo installs with no root. When brew is absent,
the bootstrap prints the manual command.

### The status bar

Windows uses YASB to draw the bar. macOS uses
[simple-bar](https://github.com/Jean-Tinland/simple-bar), a widget for the
[Übersicht](https://github.com/felixhageloh/uebersicht) desktop layer.
simple-bar has native AeroSpace support and shows on every screen. The
bootstrap installs Übersicht as a cask, then clones simple-bar into the
Übersicht widgets directory, the way it clones the antidote submodule.

simple-bar reads its look from `~/.simplebarrc`, so the repo versions it in
`simplebar/`. The config sets AeroSpace as the window manager, the YASB
palette (`#242424` background, `#4cc2ff` accent), and a widget set matched to
YASB: spaces and the front app on the left, and the clock, cpu, memory,
battery, wifi, sound, and weather on the right.

### The modifier map

whkd uses two modifiers. macOS has no free `win` key, so the move chords
move to `cmd+ctrl`. Every focus and workspace chord stays the same.

| Action | Windows (whkd) | macOS (AeroSpace) |
| --- | --- | --- |
| Focus a direction | `alt+shift+h/j/k/l` | `alt+shift+h/j/k/l` |
| Move a window | `win+shift+h/j/k/l` | `cmd+ctrl+h/j/k/l` |
| Go to workspace N | `alt+shift+N` | `alt+shift+N` |
| Send window to workspace N | `win+shift+N` | `cmd+ctrl+N` |

Focus stays on `alt+shift`, not plain `alt`. The Neovim config owns the
plain `alt` keys: `alt+h/j/k/l` move between windows, `alt+'` and `alt+;`
switch tabs, and `alt+g/c/f/r/n` open terminal floats. AeroSpace binds keys
for the whole system, so it must not claim one of those. The map above
leaves every Neovim `alt` key free.

### Command differences

A few komorebi commands have no exact AeroSpace match. The closest one is
bound instead.

| whkd | komorebi | macOS (AeroSpace) | Note |
| --- | --- | --- | --- |
| `alt+shift+return` | promote | `swap --swap-focus dfs-next` | AeroSpace has no promote. |
| `alt+arrow` | stack | `join-with <dir>` | A join plus accordion is the near match. |
| `alt+x` / `alt+y` | flip layout | set tiles / accordion | AeroSpace has no orientation flip. |
| `alt+m` | minimize | `macos-native-minimize` | The Dock or cmd+tab restores it. |
| `alt+p` | toggle-pause | service mode | `alt+p` again, or `esc`, resumes. |

## Troubleshooting

### zsh shows a configuration menu

zsh runs `zsh-newuser-install` when it finds none of `.zshenv`, `.zprofile`,
`.zshrc`, or `.zlogin` in its startup directory. The message names the
directory it checked.

An older version of these dotfiles exported `ZDOTDIR=~/.config/zsh`. After the
move to `$HOME`, a session that still carries that variable finds nothing
there. Run the bootstrap again: it removes the stale link, and it writes a
forwarding `.zshenv` when the directory has to stay.

### The prompt looks bare

oh-my-posh draws the prompt. When it is missing, the shell says so and falls
back to a plain prompt with the directory and git branch. Fix it with:

```sh
mise install -y ubi:JanDeDobbeleer/oh-my-posh
```

`./bootstrap.sh install` checks each shell tool and fails when one is
missing. A clean run does not show this problem.

### An npm install reports a bad file descriptor

See "A network home" above. The cache must not sit on NFS.

## Layout

```text
bootstrap.sh              installs mise, then runs a mise task
mise.toml                 the commands, the profiles, and the step lists
install/manifest.conf     the packages to link and the files to seed
install/tasks/step/       one script per step
install/run.sh            runs the steps of a command
install/env.sh            the shared state of every step
install/lib.sh            the link engine and the output helpers
install/doctor.sh         the doctor command
install/lock.sh           writes mise.lock for every profile
install/scan-secrets.sh   the pre-commit credential scan
install/templates/        the seeds for the host files
install/test/             container tests, including two upgrade cases
<package>/                a tree that mirrors $HOME
```
