# dotfiles

Configuration for zsh, Neovim, and the tools around them. One script
installs everything into `$HOME`. No root access is needed.

```sh
git clone --recurse-submodules https://github.com/dominicfmazza/dotfiles ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

## What the bootstrap does

1. Checks the host requirements and stops on a missing one.
2. Checks out the antidote submodule, or clones it when git cannot.
3. Links every package into `$HOME`, the way GNU stow did.
4. Seeds the host files under `~/.config/environments/` and `~/.env.json`.
5. Installs `mise` into `~/.local/bin/mise`.
6. Installs every tool in the selected profile.
7. Pulls the Neovim nightly and syncs the plugins from the lock file.
8. Installs Hack Nerd Font and the kitty terminal on Linux and macOS.
9. Warms the zsh plugin cache and makes zsh the interactive shell.

Run it again at any time. Every phase is idempotent.

## Host requirements

The host must supply these. A rootless install cannot create them.

| Requirement | Floor | Why |
| --- | --- | --- |
| POSIX shell, coreutils | any | The bootstrap runtime. |
| `git` | 2.7 | Submodules, plugins, antidote. |
| `curl` or `wget` | any | The mise installer and every download. |
| `tar`, `gzip`, `xz`, `unzip` | any | Archive extraction. |
| `zsh` | 5.8 | The interactive shell. mise has no zsh package. |
| Writable `$HOME` | — | Every install target. |
| Network to github.com and mise.jdx.dev | — | Tool downloads. |
| A true-color terminal | — | `termguicolors` and the prompt. |
| A Nerd Font on the terminal host | — | Glyphs in the prompt, Neovim, and yazi. |

On Linux and macOS the bootstrap installs Hack Nerd Font into the user font
directory, so no root is needed. On WSL the terminal runs on Windows. Install
the font on the Windows host in that case.

mise supplies everything else: node, go, rust, python, uv, zig, cmake, fzf,
fd, ripgrep, bat, jq, eza, zoxide, skim, lazygit, yazi, Neovim, every
language server, and every formatter.

A C compiler is optional. When the host has no `gcc` and no `clang`, the
bootstrap points `CC` and `CXX` at `zcc` and `zxx`. Both wrap `zig cc`, and
mise installs zig. Treesitter parsers and `cargo:` crates build with it.

`zcc` and `zxx` pin the target glibc to the host glibc. A `.so` they build
then loads on an old host such as RHEL 9. Set `ZIG_GLIBC_TARGET` to override
the version, for example `2.34`, or to `none` to use the zig default.

On a RHEL 9 host, `dnf install zsh git tar gzip xz unzip` covers
every requirement. Ask the host owner for that one command.

## Commands

```sh
./bootstrap.sh                    # link and install everything
./bootstrap.sh --profile core     # a smaller tool set
./bootstrap.sh link               # link only, no tool install
./bootstrap.sh doctor             # check an existing install
./bootstrap.sh scan               # check the repo for a leaked credential
./bootstrap.sh uninstall          # remove every link this repo owns
./bootstrap.sh --help             # every flag
```

### Profiles

The mise tool list lives in `mise/.config/mise/profiles/`. A profile decides
which files the bootstrap links into `~/.config/mise/conf.d/`.

| Profile | Files | Use for |
| --- | --- | --- |
| `core` | `00-core` | A shell on a jump host. |
| `lang` | `+ 10-lang` | A build box. |
| `editor`, `full` | `+ 20-editor` | A workstation. The default. |
| `work` | `+ 30-work` | An employer host: aws, terraform, glab, jira. |

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
|---|---|
| `~/.config/environments/hosts.sh` | Paths and identities. zsh sources it at login. |
| `~/.env.json` | Tokens. mise loads it into the environment. |
| `~/.pi/agent/settings.json` | pi settings. pi rewrites it, so it is a copy. |
| `~/.pi/agent/models.json` | Custom LLM providers and their endpoints. |
| `~/.pi/agent/auth.json` | pi credentials. Run `pi` and use `/login`. |
| `~/.config/mcp/mcp.json` | MCP server endpoints. |

The bootstrap seeds each one from `install/templates/`, and never overwrites
an existing file.

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
|---|---|---|
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

On Linux and macOS the bootstrap installs the kitty binary into
`~/.local/kitty.app` with the official installer, and links `kitty` into
`~/.local/bin`. No root is needed. On WSL, install kitty on the Windows host.

## Windows

`komorebi`, `glazewm`, and `rio/windows` target Windows. On WSL, the
bootstrap links them into the Windows user profile. Run it from WSL with
developer mode on, or run `tools/symlinkwsl.ps1` from PowerShell.

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

`./bootstrap.sh install` verifies each shell tool and fails when one is
missing, so this should not appear after a clean run.

### An npm install reports a bad file descriptor

See "A network home" above. The cache must not sit on NFS.

### A treesitter parser fails to load with a GLIBC error

Neovim reports a parser `.so` that needs a `GLIBC_2.xx` the host lacks, for
example on RHEL 9. This happens when `zig cc` builds the parser against a
glibc newer than the host.

`zcc` and `zxx` pin the target glibc to the host glibc, so a fresh build loads.
Rebuild the parsers after an upgrade:

```sh
rm -rf ~/.local/share/nvim/site/parser
nvim --headless '+qa'
```

Override the target glibc with `ZIG_GLIBC_TARGET` when detection is wrong, for
example `export ZIG_GLIBC_TARGET=2.34`.

## Layout

```text
bootstrap.sh              the installer
install/lib.sh            shared shell helpers
install/manifest.conf     package -> platform -> target map
install/scan-secrets.sh   the pre-commit credential scan
install/templates/        seeds for the host files
install/test/             container tests, including an upgrade case
<package>/                a tree that mirrors $HOME
```
