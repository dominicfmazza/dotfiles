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
8. Warms the zsh plugin cache and makes zsh the interactive shell.

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
| `libatomic.so.1` | any | The node binary links against it. |
| Writable `$HOME` | — | Every install target. |
| Network to github.com and mise.jdx.dev | — | Tool downloads. |
| A true-color terminal | — | `termguicolors` and the prompt. |
| A Nerd Font on the terminal host | — | Glyphs in the prompt, Neovim, and yazi. |

mise supplies everything else: node, go, rust, python, uv, zig, cmake, fzf,
fd, ripgrep, bat, jq, eza, zoxide, skim, lazygit, yazi, Neovim, every
language server, and every formatter.

A C compiler is optional. When the host has no `gcc` and no `clang`, the
bootstrap points `CC` and `CXX` at `zcc` and `zxx`. Both wrap `zig cc`, and
mise installs zig. Treesitter parsers and `cargo:` crates build with it.

On a RHEL 9 host, `dnf install zsh libatomic git tar gzip xz unzip` covers
every requirement. Ask the host owner for that one command.

## Commands

```sh
./bootstrap.sh                    # link and install everything
./bootstrap.sh --profile core     # a smaller tool set
./bootstrap.sh link               # link only, no tool install
./bootstrap.sh doctor             # check an existing install
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

Two files hold anything specific to one machine. Neither is in git.

- `~/.config/environments/hosts.sh` holds paths and identities. zsh sources
  it at login.
- `~/.env.json` holds tokens. mise loads it into the environment.

The bootstrap seeds both from `install/templates/`, and never overwrites an
existing one.

Add `GITHUB_TOKEN` to `~/.env.json` on a shared network. The GitHub API
allows 60 calls per hour per address, and mise reads release lists from it.

## Tests

The tests run the bootstrap in a container as a user with no root. The
default image is RHEL 9 (UBI), which matches the target fleet.

```sh
install/test/run.sh link     # link layer only. Fast.
install/test/run.sh full     # every tool, Neovim, and the plugins. Slow.
install/test/run.sh shell    # a shell in a fresh container.
```

Set `GITHUB_TOKEN` before a full run. Set `DOTFILES_TEST_BASE` to test
another distribution, for example `ubuntu:24.04`.

## Windows

`komorebi`, `glazewm`, and `rio/windows` target Windows. On WSL, the
bootstrap links them into the Windows user profile. Run it from WSL with
developer mode on, or run `tools/symlinkwsl.ps1` from PowerShell.

## Layout

```text
bootstrap.sh              the installer
install/lib.sh            shared shell helpers
install/manifest.conf     package -> platform -> target map
install/templates/        seeds for the host files
install/test/             container tests
<package>/                a tree that mirrors $HOME
```
