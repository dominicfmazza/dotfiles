# run.sh STEPS: run each step in install/tasks/step/, in order.
#
# mise starts this file from a task in mise.toml. The task flags arrive as
# usage_* variables. This file turns them into the variables that every
# step reads. install/env.sh lists them.
# shellcheck shell=sh
set -eu

: "${DOTFILES_REPO:?run this through mise or bootstrap.sh}"
MISE=${DOTFILES_MISE:-mise}

DOTFILES_PROFILE=${usage_profile:-full}
DOTFILES_PROFILE_FILES=$("$MISE" config get -f "$DOTFILES_REPO/mise.toml" \
  "vars.profile_$DOTFILES_PROFILE" 2>/dev/null) || {
  echo "error: mise.toml has no vars.profile_$DOTFILES_PROFILE" >&2
  exit 2
}
DOTFILES_ONLY=${usage_only:-}
DRY_RUN=0
[ "${usage_dry_run:-false}" = true ] && DRY_RUN=1
SKIP_TOOLS=0
[ "${usage_skip_tools:-false}" = true ] && SKIP_TOOLS=1
CONFLICT=report
[ "${usage_backup:-false}" = true ] && CONFLICT=backup
[ "${usage_adopt:-false}" = true ] && CONFLICT=adopt
[ "${usage_force:-false}" = true ] && CONFLICT=force
RUN_STAMP=$(date +%Y%m%d%H%M%S)
export DOTFILES_PROFILE DOTFILES_PROFILE_FILES DOTFILES_ONLY DRY_RUN \
  SKIP_TOOLS CONFLICT RUN_STAMP

failed=''
for step in $1; do
  script="$DOTFILES_REPO/install/tasks/step/$step"
  [ -f "$script" ] || {
    echo "error: no step named $step in install/tasks/step" >&2
    exit 2
  }
  case "$step" in
  tools | neovim | wm) [ "$SKIP_TOOLS" = 1 ] && continue ;;
  esac
  # A step warns for a problem that the host can live with. A non-zero
  # exit means the host cannot use what the step installs.
  if ! sh "$script"; then
    [ "$step" = preflight ] && exit 1
    failed="$failed $step"
  fi
done

if [ -n "$failed" ]; then
  printf '\nerror: these steps failed:%s\n' "$failed" >&2
  exit 1
fi
