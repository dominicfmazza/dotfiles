#!/bin/sh
# bootstrap.sh: install these dotfiles on a host, with no root access.
#
# The commands and flags are mise tasks. This file installs mise when the
# host has none, and then hands every argument to mise.
#
#   ./bootstrap.sh [install|link|doctor|uninstall|scan|lock] [flags]
#   ./bootstrap.sh install --help        the flags of a command
#
# After the first install, `mise run <command>` does the same thing.
# What gets installed is data, not code:
#   install/manifest.conf     packages to link, files to seed
#   mise.toml [vars]          profiles and the steps of each command
#   mise/.config/mise/        the tools of each profile, and mise.lock
set -eu

REPO=$(cd "$(dirname "$0")" && pwd -P)
MISE="$HOME/.local/bin/mise"

case "${1:-install}" in
-h | --help)
  sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
  ;;
-*) set -- install "$@" ;;
esac
[ $# -eq 0 ] && set -- install

if [ ! -x "$MISE" ]; then
  echo "==> Installing mise into ~/.local/bin"
  mkdir -p "$HOME/.local/bin"
  tmp=$(mktemp "${TMPDIR:-/tmp}/mise-install.XXXXXX")
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --proto '=https' --tlsv1.2 https://mise.run -o "$tmp"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$tmp" https://mise.run
  else
    echo "error: curl or wget is needed" >&2
    exit 1
  fi
  MISE_INSTALL_PATH="$MISE" sh "$tmp" >/dev/null
  rm -f "$tmp"
  [ -x "$MISE" ] || { echo "error: the mise install failed" >&2; exit 1; }
fi

# mise asks before it reads tasks from a new config file. The repo is the
# trusted source of this host's config, so trust it here.
"$MISE" trust --quiet "$REPO/mise.toml" >/dev/null 2>&1 || true
exec "$MISE" -C "$REPO" run --quiet "$@"
