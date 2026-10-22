# Shared state for every step. A step sources this file first.
#
# install/run.sh exports the DOTFILES_* run flags. A step that runs alone,
# through `mise run step:<name>`, gets the defaults below.
# shellcheck shell=sh
set -eu

: "${DOTFILES_REPO:=${MISE_CONFIG_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd -P)}}"
REPO_ROOT=$DOTFILES_REPO
export REPO_ROOT DOTFILES_REPO
. "$REPO_ROOT/install/lib.sh"

: "${DOTFILES_PROFILE:=full}"
: "${DOTFILES_PROFILE_FILES:=}"
: "${DOTFILES_ONLY:=}"
: "${DRY_RUN:=0}"
: "${CONFLICT:=report}"
: "${RUN_STAMP:=$(date +%Y%m%d%H%M%S)}"
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
export DRY_RUN CONFLICT RUN_STAMP XDG_CONFIG_HOME XDG_DATA_HOME

PLATFORM=$(detect_platform)
ARCH=$(detect_arch)
export PLATFORM

MISE_BIN=${DOTFILES_MISE:-$HOME/.local/bin/mise}

want_package() {
  # want_package NAME PLATFORMS. --only overrides the platform list.
  if [ -n "$DOTFILES_ONLY" ]; then
    for _wp in $DOTFILES_ONLY; do
      [ "$_wp" = "$1" ] && return 0
    done
    return 1
  fi
  on_platform "$2"
}
