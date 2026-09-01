#!/bin/sh
# bootstrap.sh: install these dotfiles on any host, with no root access.
#
# Usage:
#   ./bootstrap.sh [command] [options]
#
# Commands:
#   install     link the packages and install the tools. The default.
#   link        link the packages only.
#   doctor      check an existing install and report.
#   scan        check the repo for a leaked credential.
#   uninstall   remove every link this repo owns.
#
# Options:
#   -p, --profile NAME   core | lang | editor | full | work   (default: full)
#   -o, --only PKG       one package. Repeat the flag for more.
#   -n, --dry-run        print the actions. Change nothing.
#       --skip-tools     do not run mise, bob, or the plugin sync.
#       --backup         move a conflicting file to <name>.bak.<stamp>.
#       --adopt          move a conflicting file into the repo, then link.
#       --force          delete a conflicting file, then link.
#   -h, --help           print this text.
#
# See install/manifest.conf for the package map.

set -eu

REPO_ROOT=$(cd "$(dirname "$0")" && pwd -P)
export REPO_ROOT
. "$REPO_ROOT/install/lib.sh"

COMMAND=install
PROFILE=full
ONLY=''
DRY_RUN=0
SKIP_TOOLS=0
CONFLICT=report
RUN_STAMP=$(date +%Y%m%d%H%M%S)
MANIFEST="$REPO_ROOT/install/manifest.conf"
SHARED_MAP=''
export DRY_RUN CONFLICT RUN_STAMP SHARED_MAP

MISE_BIN="$HOME/.local/bin/mise"
NVIM_MIN=0.13

usage() {
  sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
}

cleanup() {
  [ -n "${SHARED_MAP:-}" ] && rm -f "$SHARED_MAP"
  return 0
}
trap cleanup EXIT INT TERM

# ------------------------------------------------------------------- args ----

while [ $# -gt 0 ]; do
  case $1 in
    install | link | doctor | uninstall | scan) COMMAND=$1 ;;
    -p | --profile)
      shift
      PROFILE=${1:?--profile needs a name}
      ;;
    -o | --only)
      shift
      ONLY="$ONLY ${1:?--only needs a package}"
      ;;
    -n | --dry-run) DRY_RUN=1 ;;
    --skip-tools) SKIP_TOOLS=1 ;;
    --backup) CONFLICT=backup ;;
    --adopt) CONFLICT=adopt ;;
    --force) CONFLICT=force ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "unknown argument: $1" ;;
  esac
  shift
done

case $PROFILE in
  core | lang | editor | full | work) ;;
  *) die "unknown profile: $PROFILE" ;;
esac

PLATFORM=$(detect_platform)
ARCH=$(detect_arch)
export PLATFORM
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
export XDG_CONFIG_HOME XDG_DATA_HOME

# --------------------------------------------------------------- preflight ----

phase_preflight() {
  info "Preflight on $PLATFORM/$ARCH"

  [ "$PLATFORM" = unknown ] && die "unsupported platform: $(uname -s)"

  for c in git tar; do
    if have "$c"; then
      ok "$c $(tool_version "$c" --version)"
    else
      fail "$c is missing"
    fi
  done

  if have curl || have wget; then
    ok "a downloader is present"
  else
    fail "curl or wget is needed"
  fi

  for c in unzip gzip xz; do
    if have "$c"; then
      ok "$c"
    else
      warn "$c is missing. Some archives will not unpack."
    fi
  done

  if have git; then
    gv=$(tool_version git --version)
    version_ge "$gv" 2.7 || fail "git $gv is too old. Need 2.7 or later."
  fi

  if have zsh; then
    zv=$(tool_version zsh --version)
    if version_ge "$zv" 5.8; then
      ok "zsh $zv"
    else
      warn "zsh $zv is old. Need 5.8 for every plugin."
    fi
  else
    fail "zsh is missing. mise has no zsh package. Ask the host owner for it."
  fi

  [ -w "$HOME" ] || fail "\$HOME is not writable"

  if have cc || have gcc || have clang; then
    ok "a C compiler is present"
  else
    warn "no C compiler. The bootstrap will point CC at zcc, which wraps zig cc."
  fi

  tls_probe && ok "HTTPS to github.com works"

  [ "$FAIL_COUNT" -gt 0 ] \
    && die "$FAIL_COUNT requirement(s) failed. Fix them and run again."
  return 0
}

# ------------------------------------------------------------- submodules ----

# ------------------------------------------------------------------- hooks ----

phase_hooks() {
  # Install the secret scan as a pre-commit hook. This repo is public, so a
  # token or an internal hostname must never reach a commit.
  info "Git hooks"
  if [ ! -d "$REPO_ROOT/.git" ]; then
    skip "not a git checkout"
    return 0
  fi

  hook="$REPO_ROOT/.git/hooks/pre-commit"
  if [ -e "$hook" ] && [ ! -L "$hook" ]; then
    warn "$(pretty "$hook") exists and is not a link. Leaving it alone."
    return 0
  fi
  if [ -L "$hook" ] && [ "$(readlink "$hook")" = "../../install/scan-secrets.sh" ]; then
    skip "the pre-commit scan hook is installed"
    return 0
  fi
  act mkdir -p "$REPO_ROOT/.git/hooks"
  act ln -sf ../../install/scan-secrets.sh "$hook"
  ok "the pre-commit scan hook is installed"
}

phase_submodules() {
  info "Submodules"
  sm_dir="$REPO_ROOT/zsh/.config/zsh/.antidote"

  if [ -f "$sm_dir/antidote.zsh" ]; then
    ok "antidote is present"
    return 0
  fi

  if [ -e "$REPO_ROOT/.git" ] \
    && act git -C "$REPO_ROOT" submodule update --init --recursive 2>/dev/null; then
    ok "antidote is checked out"
    return 0
  fi

  # No usable submodule state. Clone antidote on its own.
  warn "the submodule checkout failed. Cloning antidote directly."
  act rm -rf "$sm_dir"
  if act git clone --quiet --depth 1 --branch v1.10.3 \
    https://github.com/mattmc3/antidote.git "$sm_dir"; then
    ok "antidote is cloned"
  else
    fail "antidote is missing. zsh will start with no plugin."
  fi
}

# ------------------------------------------------------------------- links ----

want_package() {
  # want_package NAME PLATFORMS
  if [ -n "$ONLY" ]; then
    for p in $ONLY; do
      [ "$p" = "$1" ] && return 0
    done
    return 1
  fi
  [ "$2" = all ] && return 0
  case ",$2," in
    *",$PLATFORM,"*) return 0 ;;
    *) return 1 ;;
  esac
}

resolve_target() {
  # resolve_target SPEC. Prints the destination root. Fails when this
  # platform has no such root.
  case $1 in
    home) printf '%s\n' "$HOME" ;;
    xdg:*) printf '%s/%s\n' "$XDG_CONFIG_HOME" "${1#xdg:}" ;;
    win:*)
      wh=$(win_home) || return 1
      sub=${1#win:}
      if [ "$sub" = . ]; then
        printf '%s\n' "$wh"
      else
        printf '%s/%s\n' "$wh" "$sub"
      fi
      ;;
    *) return 1 ;;
  esac
}

scan_shared_dirs() {
  # Write every destination directory that has to stay a real directory.
  #
  # Two sources feed the list:
  #   1. A directory that two or more selected packages both need. zsh and
  #      nvim both want ~/.config, so neither may link the whole path.
  #   2. A directory that a tool writes into at runtime. mise unpacks every
  #      tool under ~/.local/share, so ~/.local must never become a link
  #      into this repo.
  SHARED_MAP="${TMPDIR:-/tmp}/dotshared.$$"
  all="${TMPDIR:-/tmp}/dotdirs.$$"
  : >"$all"

  while read -r pkg platforms target flags <&3; do
    case "$pkg" in '' | \#*) continue ;; esac
    want_package "$pkg" "$platforms" || continue
    dst=$(resolve_target "$target") || continue
    [ -d "$REPO_ROOT/$pkg" ] || continue

    find "$REPO_ROOT/$pkg" -mindepth 1 -type d \
      -not -path '*/.git*' -not -name profiles 2>/dev/null \
      | sed -e "s|^$REPO_ROOT/$pkg|$dst|" >>"$all"
  done 3<"$MANIFEST"

  sort "$all" | uniq -d >"$SHARED_MAP"
  rm -f "$all"

  for d in "$HOME/.local" "$HOME/.local/bin" "$HOME/.local/share" \
    "$HOME/.local/state" "$HOME/.cache" "$XDG_CONFIG_HOME" \
    "$XDG_DATA_HOME" "$HOME/.config/mise"; do
    printf '%s\n' "$d" >>"$SHARED_MAP"
  done
  export SHARED_MAP
}

phase_link() {
  info "Links"
  scan_shared_dirs

  # Read the manifest on descriptor 3. A helper that reads stdin, such as
  # the cmd.exe probe in win_home, would eat the rest of the file otherwise.
  while read -r pkg platforms target flags <&3; do
    case "$pkg" in '' | \#*) continue ;; esac
    want_package "$pkg" "$platforms" || continue

    dst=$(resolve_target "$target") || {
      skip "$pkg (no target on $PLATFORM)"
      continue
    }
    src="$REPO_ROOT/$pkg"
    [ -d "$src" ] || {
      warn "$pkg is in the manifest but not on disk"
      continue
    }

    say "  $C_DIM$pkg -> $(pretty "$dst")$C_OFF"
    act mkdir -p "$dst"
    mode=fold
    case " $flags " in *" nofold "*) mode=nofold ;; esac
    link_tree "$src" "$dst" "$mode" 'profiles' "$SHARED_MAP"
  done 3<"$MANIFEST"

  link_mise_profiles
}

link_mise_profiles() {
  # Link the profile files this run wants into ~/.config/mise/conf.d.
  want_package mise "linux,wsl,darwin" || return 0
  srcdir="$REPO_ROOT/mise/.config/mise/profiles"
  dstdir="$XDG_CONFIG_HOME/mise/conf.d"
  [ -d "$srcdir" ] || return 0

  # An old stow install may have linked ~/.config/mise straight into the
  # repo. Writing conf.d through that link would create host state inside
  # the checkout, so turn it back into a real directory first.
  misedir="$XDG_CONFIG_HOME/mise"
  if [ -L "$misedir" ] && owned_by_repo "$misedir"; then
    act rm -f "$misedir"
    act mkdir -p "$misedir"
    make_link "$REPO_ROOT/mise/.config/mise/config.toml" "$misedir/config.toml"
    ok "$(pretty "$misedir") is a real directory again"
  fi

  case $PROFILE in
    core) files='00-core.toml' ;;
    lang) files='00-core.toml 10-lang.toml' ;;
    editor | full) files='00-core.toml 10-lang.toml 20-editor.toml' ;;
    work) files='00-core.toml 10-lang.toml 20-editor.toml 30-work.toml' ;;
  esac

  say "  ${C_DIM}mise profile: $PROFILE$C_OFF"
  act mkdir -p "$dstdir"

  # Drop a profile file this run does not want. The test uses -e OR -L,
  # because -e alone is false for a link whose target is already gone.
  for old in "$dstdir"/*.toml; do
    [ -e "$old" ] || [ -L "$old" ] || continue
    base=$(basename "$old")
    keep=0
    for f in $files; do
      [ "$f" = "$base" ] && keep=1
    done
    if [ "$keep" = 0 ] && owned_by_repo "$old"; then
      act rm -f "$old"
      ok "$(pretty "$old") removed"
    fi
  done

  for f in $files; do
    [ -e "$srcdir/$f" ] || continue
    make_link "$srcdir/$f" "$dstdir/$f"
  done
}

# -------------------------------------------------------------------- seed ----

phase_seed() {
  info "Host files"
  tpl="$REPO_ROOT/install/templates"
  seed_file "$tpl/hosts.sh" "$XDG_CONFIG_HOME/environments/hosts.sh"
  seed_file "$tpl/paths.sh" "$XDG_CONFIG_HOME/environments/paths.sh"
  seed_file "$tpl/langs.sh" "$XDG_CONFIG_HOME/environments/langs.sh"
  seed_file "$tpl/env.json" "$HOME/.env.json"

  # pi files that hold a secret or a host endpoint. The repo never carries
  # them. settings.json is a seed and not a link, because pi rewrites it at
  # runtime and a link would make every /model change dirty the checkout.
  if want_package pi "linux,wsl,darwin"; then
    seed_file "$tpl/pi/settings.json" "$HOME/.pi/agent/settings.json"
    seed_file "$tpl/pi/models.json" "$HOME/.pi/agent/models.json"
    seed_file "$tpl/pi/mcp.json" "$XDG_CONFIG_HOME/mcp/mcp.json"
    if [ -f "$HOME/.pi/agent/auth.json" ]; then
      skip "~/.pi/agent/auth.json (kept)"
    else
      say "  ${C_DIM}No pi credential yet. Run 'pi' and use /login.$C_OFF"
    fi
  fi

  have cc && return 0
  have gcc && return 0
  have clang && return 0

  langs="$XDG_CONFIG_HOME/environments/langs.sh"
  [ -f "$langs" ] || return 0
  grep -q zcc "$langs" 2>/dev/null && return 0

  if [ "$DRY_RUN" = 1 ]; then
    skip "would point CC and CXX at zcc and zxx"
    return 0
  fi
  cat >>"$langs" <<'EOF'

# Added by bootstrap.sh: this host has no gcc and no clang.
export CC="$HOME/.local/bin/zcc"
export CXX="$HOME/.local/bin/zxx"
EOF
  ok "CC and CXX point at zcc and zxx"
}

# -------------------------------------------------------------------- mise ----

phase_mise() {
  info "mise"
  if [ -x "$MISE_BIN" ]; then
    ok "mise $("$MISE_BIN" --version 2>/dev/null | head -1)"
    return 0
  fi
  act mkdir -p "$HOME/.local/bin"
  tmp="${TMPDIR:-/tmp}/mise-install.$$"
  fetch https://mise.run "$tmp"
  if [ "$DRY_RUN" = 1 ]; then
    skip "would run the mise installer"
    return 0
  fi
  MISE_INSTALL_PATH="$MISE_BIN" sh "$tmp" >/dev/null 2>&1 || true
  rm -f "$tmp"
  [ -x "$MISE_BIN" ] || die "the mise install failed"
  ok "mise $("$MISE_BIN" --version | head -1)"
}

phase_tools() {
  info "Tools"
  if [ ! -x "$MISE_BIN" ]; then
    warn "no mise. Skipping the tool install."
    return 0
  fi
  if [ "$DRY_RUN" = 1 ]; then
    skip "would run mise install"
    return 0
  fi

  # mise reads release lists from the GitHub API. An unauthenticated caller
  # gets 60 requests per hour, shared with every host behind the same NAT.
  # A token raises that to 5000.
  if [ -z "${GITHUB_TOKEN:-}" ] && [ -z "${GITHUB_API_TOKEN:-}" ]; then
    if [ -f "$HOME/.env.json" ] \
      && gh_tok=$(sed -n 's/.*"GITHUB_TOKEN"[[:space:]]*:[[:space:]]*"\([^"]\{1,\}\)".*/\1/p' "$HOME/.env.json" | head -1) \
      && [ -n "$gh_tok" ]; then
      GITHUB_TOKEN=$gh_tok
      export GITHUB_TOKEN
      ok "a GitHub token from ~/.env.json raises the API limit"
    else
      warn "no GITHUB_TOKEN. The GitHub API allows 60 calls per hour per address."
      say "  ${C_DIM}Add GITHUB_TOKEN to ~/.env.json when a download hits the limit.$C_OFF"
    fi
  fi

  # zig first, because a source build needs a compiler and a linker.
  "$MISE_BIN" install --yes zig >/dev/null 2>&1 || true

  # A host with no gcc still has to build a tool that ships no binary, such
  # as lua. Point the build at zig for this run.
  if ! have cc && ! have gcc && ! have clang; then
    if [ -x "$HOME/.local/bin/zcc" ]; then
      CC="$HOME/.local/bin/zcc"
      CXX="$HOME/.local/bin/zxx"
      export CC CXX
      ok "CC points at zcc for this run"
    fi
  fi

  # Two passes. A rate limit or a slow mirror often clears on the retry.
  if "$MISE_BIN" install --yes; then
    ok "every tool is installed"
  else
    warn "the first pass left tools missing. Retrying once."
    if "$MISE_BIN" install --yes; then
      ok "every tool is installed after the retry"
    else
      warn "some tools still fail. Run 'mise install' to see which."
    fi
  fi
  "$MISE_BIN" reshim >/dev/null 2>&1 || true
}

# ------------------------------------------------------------------ neovim ----

phase_neovim() {
  info "Neovim"

  # mise supplies the nightly. bob stays out of the picture: its release
  # binary needs glibc 2.39, which RHEL 9 does not have.
  nv=''
  if [ -x "$MISE_BIN" ]; then
    nv=$("$MISE_BIN" which nvim 2>/dev/null || true)
  fi
  [ -n "$nv" ] || nv=$(command -v nvim 2>/dev/null || true)
  # An older install of this repo used bob. Keep that path working.
  [ -n "$nv" ] || {
    [ -x "$XDG_DATA_HOME/bob/nvim-bin/nvim" ] && nv="$XDG_DATA_HOME/bob/nvim-bin/nvim"
  }

  if [ -z "$nv" ] || [ ! -x "$nv" ]; then
    warn "no nvim binary. Run 'mise install neovim' and try again."
    return 0
  fi

  nvv=$(tool_version "$nv" --version)
  if version_ge "$nvv" "$NVIM_MIN"; then
    ok "nvim $nvv"
  else
    warn "nvim $nvv is too old. init.lua needs $NVIM_MIN or later."
  fi

  if [ "$DRY_RUN" = 1 ]; then
    skip "would sync the plugins from nvim-pack-lock.json"
    return 0
  fi

  # A headless start makes vim.pack clone every plugin at the locked commit.
  if "$nv" --headless '+qa' >/dev/null 2>&1; then
    ok "plugins are in sync"
  else
    warn "the plugin sync reported an error. Open nvim and read :messages."
  fi
}

# ------------------------------------------------------------------- shell ----

phase_shell() {
  info "Shell"
  if ! have zsh; then
    warn "no zsh. Skipping the shell setup."
    return 0
  fi

  if [ "$DRY_RUN" = 1 ]; then
    skip "would warm the antidote plugin cache"
  elif zsh -ic true >/dev/null 2>&1; then
    ok "the plugin cache is warm"
  else
    warn "the first zsh start reported an error. Open zsh and read it."
  fi

  case "${SHELL:-}" in
    */zsh)
      ok "zsh is the login shell"
      return 0
      ;;
  esac

  zpath=$(command -v zsh)
  for rc in "$HOME/.profile" "$HOME/.bash_profile"; do
    if [ -f "$rc" ] && grep -q 'bootstrap.sh: start zsh' "$rc" 2>/dev/null; then
      skip "$(pretty "$rc") already starts zsh"
      continue
    fi
    if [ "$DRY_RUN" = 1 ]; then
      skip "would add a zsh start block to $(pretty "$rc")"
      continue
    fi
    cat >>"$rc" <<EOF

# bootstrap.sh: start zsh when this is an interactive login shell.
case \$- in
  *i*)
    [ -z "\${ZSH_VERSION:-}" ] && [ -x "$zpath" ] && exec "$zpath" -l
    ;;
esac
EOF
    ok "$(pretty "$rc") now starts zsh"
  done
  say "  ${C_DIM}To change the login shell instead: chsh -s $zpath$C_OFF"
}

# ------------------------------------------------------------------ doctor ----

check_bin() {
  # Look for a tool on PATH, and also under the mise shims. A doctor run
  # from a plain sh has not activated mise, so the shims are not on PATH.
  if p=$(command -v "$1" 2>/dev/null); then
    ok "$1 $(tool_version "$1" --version) ($p)"
  elif [ -x "$XDG_DATA_HOME/mise/shims/$1" ]; then
    p="$XDG_DATA_HOME/mise/shims/$1"
    ok "$1 $(tool_version "$p" --version) (shim)"
  else
    warn "$1 is missing"
  fi
}

phase_doctor() {
  info "Doctor on $PLATFORM/$ARCH"

  say "  ${C_DIM}links$C_OFF"
  broken=0
  for d in "$HOME" "$HOME/.local/bin" "$XDG_CONFIG_HOME" "$XDG_CONFIG_HOME/mise/conf.d"; do
    [ -d "$d" ] || continue
    for l in "$d"/* "$d"/.[!.]*; do
      [ -L "$l" ] || continue
      owned_by_repo "$l" || continue
      if [ -e "$l" ]; then
        ok "$(pretty "$l")"
      else
        fail "$(pretty "$l") is broken"
        broken=$((broken + 1))
      fi
    done
  done
  [ "$broken" = 0 ] && ok "no broken link"

  say "  ${C_DIM}host files$C_OFF"
  for f in "$XDG_CONFIG_HOME/environments/hosts.sh" \
    "$XDG_CONFIG_HOME/environments/paths.sh" \
    "$XDG_CONFIG_HOME/environments/langs.sh" \
    "$HOME/.env.json"; do
    if [ -f "$f" ]; then
      ok "$(pretty "$f")"
    else
      warn "$(pretty "$f") is missing"
    fi
  done

  say "  ${C_DIM}secrets$C_OFF"
  if [ -x "$REPO_ROOT/install/scan-secrets.sh" ]; then
    if scan_out=$("$REPO_ROOT/install/scan-secrets.sh" 2>&1); then
      ok "no credential in the repo"
    else
      fail "the repo holds a credential or an internal hostname"
      printf '%s\n' "$scan_out" | sed 's/^/    /' >&2
    fi
  fi
  if [ -e "$REPO_ROOT/.git/hooks/pre-commit" ]; then
    ok "the pre-commit scan hook is installed"
  else
    warn "no pre-commit hook. Run: ./bootstrap.sh link"
  fi

  say "  ${C_DIM}binaries$C_OFF"
  check_bin zsh
  check_bin git
  if [ -x "$MISE_BIN" ]; then
    ok "mise $("$MISE_BIN" --version | head -1)"
  else
    warn "mise is missing"
  fi
  for t in nvim fzf rg fd bat jq eza zoxide lazygit yazi oh-my-posh; do
    check_bin "$t"
  done

  if have cc || have gcc || have clang; then
    ok "a system C compiler is present"
  elif have zig || [ -x "$HOME/.local/bin/zcc" ]; then
    ok "zig supplies the C compiler (zcc)"
  else
    warn "no C compiler. Treesitter parsers will not build."
  fi

  if have nvim; then
    nvv=$(tool_version nvim --version)
  elif [ -x "$XDG_DATA_HOME/mise/shims/nvim" ]; then
    nvv=$(tool_version "$XDG_DATA_HOME/mise/shims/nvim" --version)
  elif [ -x "$XDG_DATA_HOME/bob/nvim-bin/nvim" ]; then
    nvv=$(tool_version "$XDG_DATA_HOME/bob/nvim-bin/nvim" --version)
  else
    nvv=''
  fi
  if [ -n "$nvv" ]; then
    if version_ge "$nvv" "$NVIM_MIN"; then
      ok "nvim $nvv meets the $NVIM_MIN floor"
    else
      fail "nvim $nvv is below the $NVIM_MIN floor"
    fi
  fi

  say ''
  if [ "$FAIL_COUNT" -gt 0 ]; then
    say "${C_RED}$FAIL_COUNT problem(s)${C_OFF}, ${C_YEL}$WARN_COUNT warning(s)${C_OFF}"
    return 1
  fi
  say "${C_GRN}healthy${C_OFF}, ${C_YEL}$WARN_COUNT warning(s)${C_OFF}"
}

# --------------------------------------------------------------- uninstall ----

phase_uninstall() {
  info "Uninstall"
  unlink_tree "$HOME/.local/bin"
  unlink_tree "$XDG_CONFIG_HOME"
  unlink_tree "$HOME"
  say "  ${C_DIM}Files under ~/.config/environments stay in place.$C_OFF"
}

# -------------------------------------------------------------------- main ----

case $COMMAND in
  link)
    phase_preflight
    phase_submodules
    phase_hooks
    phase_link
    phase_seed
    ;;
  install)
    phase_preflight
    phase_submodules
    phase_hooks
    phase_link
    phase_seed
    if [ "$SKIP_TOOLS" = 1 ]; then
      info "Tools skipped"
    else
      phase_mise
      phase_tools
      phase_neovim
    fi
    phase_shell
    say ''
    info "Done. Open a new shell."
    [ "$WARN_COUNT" -gt 0 ] && say "${C_YEL}$WARN_COUNT warning(s) above.${C_OFF}"
    ;;
  doctor) phase_doctor ;;
  uninstall) phase_uninstall ;;
  scan) exec "$REPO_ROOT/install/scan-secrets.sh" ;;
esac
