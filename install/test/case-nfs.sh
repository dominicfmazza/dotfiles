#!/bin/sh
# Case: a network home. Proves the cache redirect and the zsh startup order.
#
# A real NFS mount needs a privileged server container, so this case forces
# the two conditions that a network home creates:
#   1. DOTFILES_CACHE_ROOT set, which is what .zshenv computes on NFS.
#   2. A read-only home cache directory, which is what a rejected lock looks
#      like to a tool that cannot write its lock file.
#
# It also proves the startup-order fix: a NON-LOGIN interactive zsh must load
# .zshrc. That failed before, because ZDOTDIR was set in .zprofile.
set -eu

cd "$HOME/dotfiles"
FAILED=0

check() {
  desc=$1
  shift
  if "$@"; then
    printf 'PASS  %s\n' "$desc"
  else
    printf 'FAIL  %s\n' "$desc"
    FAILED=$((FAILED + 1))
  fi
}

echo "=== 1. link the zsh package"
./bootstrap.sh link -o zsh >/dev/null 2>&1

echo
echo "=== 2. every zsh file sits in \$HOME, not in a ZDOTDIR"
check "~/.zshenv" test -L "$HOME/.zshenv"
check "~/.zprofile" test -L "$HOME/.zprofile"
check "~/.zshrc" test -L "$HOME/.zshrc"
check "~/.zsh_plugins.txt" test -L "$HOME/.zsh_plugins.txt"
check "~/.antidote" test -e "$HOME/.antidote/antidote.zsh"
check "no ~/.config/zsh directory" test ! -d "$HOME/.config/zsh"

echo
echo "=== 3. a NON-LOGIN interactive zsh loads .zshrc"
# This is the regression that broke the shell. ZDOTDIR lived in .zprofile,
# which a non-login shell never reads, so .zshrc never loaded.
out=$(env -i HOME="$HOME" TERM=xterm PATH=/usr/bin:/bin \
  zsh -i -c 'echo "RC=${ZSH_AUTOSUGGEST_USE_ASYNC:-unset}"' 2>/dev/null | tail -1)
check "non-login interactive zsh reads .zshrc" test "$out" = "RC=true"

out=$(env -i HOME="$HOME" TERM=xterm PATH=/usr/bin:/bin \
  zsh -c 'echo "ZDOTDIR=${ZDOTDIR:-unset}"' 2>/dev/null | tail -1)
check "ZDOTDIR stays unset" test "$out" = "ZDOTDIR=unset"

echo
echo "=== 4. a local home keeps its cache on the home"
out=$(env -i HOME="$HOME" TERM=xterm PATH=/usr/bin:/bin \
  zsh -c 'echo "${DOTFILES_CACHE_ROOT:-none}"' 2>/dev/null | tail -1)
check "no redirect on a local home" test "$out" = "none"
out=$(env -i HOME="$HOME" TERM=xterm PATH=/usr/bin:/bin \
  zsh -c 'echo "$XDG_CACHE_HOME"' 2>/dev/null | tail -1)
check "XDG_CACHE_HOME is on the home" test "$out" = "$HOME/.cache"

echo
echo "=== 5. a network home redirects every lock-taking cache"
# Force the branch .zshenv takes when the home cannot hold a lock.
CROOT=/var/tmp/nfs-sim-cache
rm -rf "$CROOT"
probe() {
  env -i HOME="$HOME" TERM=xterm PATH=/usr/bin:/bin \
    DOTFILES_CACHE_ROOT="$CROOT" \
    zsh -c "echo \"\${$1:-unset}\"" 2>/dev/null | tail -1
}

check "MISE_CACHE_DIR goes local" test "$(probe MISE_CACHE_DIR)" = "$CROOT/mise"
check "npm cache goes local" test "$(probe npm_config_cache)" = "$CROOT/npm"
check "UV_CACHE_DIR goes local" test "$(probe UV_CACHE_DIR)" = "$CROOT/uv"
check "PIP_CACHE_DIR goes local" test "$(probe PIP_CACHE_DIR)" = "$CROOT/pip"
check "GOMODCACHE goes local" test "$(probe GOMODCACHE)" = "$CROOT/go-mod"
check "GOCACHE goes local" test "$(probe GOCACHE)" = "$CROOT/go-build"
check "YARN_CACHE_FOLDER goes local" test "$(probe YARN_CACHE_FOLDER)" = "$CROOT/yarn"
check "XDG_CACHE_HOME goes local" test "$(probe XDG_CACHE_HOME)" = "$CROOT"
check "the cache root is created" test -d "$CROOT"
check "the cache root is private" test "$(stat -c %a "$CROOT" 2>/dev/null)" = "700"

echo
echo "=== 6. tool installs stay on the home, so a reboot loses nothing"
check "MISE_DATA_DIR stays on the home" test "$(probe MISE_DATA_DIR)" = "$HOME/.local/share/mise"
check "MISE_STATE_DIR stays on the home" test "$(probe MISE_STATE_DIR)" = "$HOME/.local/state/mise"
rm -rf "$CROOT"

echo
echo "=== 7. a lock-hostile cache does not break the shell"
# A home cache that rejects a write is what a failed flock looks like.
# The shell must still reach a prompt.
mkdir -p "$HOME/.cache"
rm -f "$HOME/.cache/.dotfiles-lock-ok"
chmod 500 "$HOME/.cache"
out=$(env -i HOME="$HOME" TERM=xterm PATH=/usr/bin:/bin \
  zsh -i -c 'echo ALIVE' 2>/dev/null | tail -1)
chmod 700 "$HOME/.cache"
check "zsh survives an unwritable home cache" test "$out" = "ALIVE"

echo
echo "=== 8. every mise tool carries an exact version"
# A pin means mise resolves from disk and calls no release API. On an
# ephemeral host the cache is empty after every boot, so an unpinned tool
# costs one HTTP call per boot.
unpinned=$(grep -hE '^[^#]*=' "$HOME"/dotfiles/mise/.config/mise/profiles/*.toml \
  | grep -E '"latest"|= *.latest' || true)
if [ -n "$unpinned" ]; then
  printf 'FAIL  these tools are not pinned:\n%s\n' "$unpinned"
  FAILED=$((FAILED + 1))
else
  printf 'PASS  every tool is pinned\n'
fi
check "npm.package_manager is not auto" grep -q 'npm.package_manager = "npm"' \
  "$HOME/dotfiles/mise/.config/mise/config.toml"

echo
echo "=== 9. the preflight names the filesystem"
./bootstrap.sh link -n -o zsh >/tmp/pre.log 2>&1 || true
check "preflight reports the home filesystem" grep -q '\$HOME is on' /tmp/pre.log

echo
if [ "$FAILED" -gt 0 ]; then
  echo "RESULT: $FAILED check(s) failed"
  exit 1
fi
echo "RESULT: every check passed"
