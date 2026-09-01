#!/bin/sh
# Case: link only. No tool install. Checks the link layer and the seeds.
set -eu

cd "$HOME/dotfiles"
FAILED=0

check() {
  # check DESCRIPTION TEST...
  desc=$1
  shift
  if "$@"; then
    printf 'PASS  %s\n' "$desc"
  else
    printf 'FAIL  %s\n' "$desc"
    FAILED=$((FAILED + 1))
  fi
}

is_link_to() {
  # is_link_to LINK EXPECTED_SUFFIX
  [ -L "$1" ] || return 1
  case "$(readlink "$1")" in *"$2") return 0 ;; esac
  return 1
}

echo "=== 1. dry run changes nothing"
./bootstrap.sh link --dry-run >/dev/null
check "no ~/.zshenv after a dry run" test ! -e "$HOME/.zshenv"

echo
echo "=== 2. link"
./bootstrap.sh link

echo
echo "=== 3. links point into the repo"
check "~/.zshenv" is_link_to "$HOME/.zshenv" dotfiles/zsh/.zshenv
check "~/.zprofile" is_link_to "$HOME/.zprofile" dotfiles/zsh/.zprofile
check "~/.aliases" is_link_to "$HOME/.aliases" dotfiles/zsh/.aliases
check "~/.omp.yaml" is_link_to "$HOME/.omp.yaml" dotfiles/zsh/.omp.yaml
check "~/.config/zsh" is_link_to "$HOME/.config/zsh" dotfiles/zsh/.config/zsh
check "~/.config/nvim" is_link_to "$HOME/.config/nvim" dotfiles/nvim/.config/nvim
check "~/.config/yazi" is_link_to "$HOME/.config/yazi" dotfiles/yazi/.config/yazi
check "~/.config/lazygit" is_link_to "$HOME/.config/lazygit" dotfiles/lazygit/.config/lazygit
check "~/.local/bin/zcc" is_link_to "$HOME/.local/bin/zcc" scripts/.local/bin/zcc
check "~/.wezterm.lua" is_link_to "$HOME/.wezterm.lua" dotfiles/wezterm/.wezterm.lua

echo
echo "=== 3b. runtime directories stay real"
check "~/.local is a real directory" sh -c '[ -d "$HOME/.local" ] && [ ! -L "$HOME/.local" ]'
check "~/.local/bin is a real directory" sh -c '[ -d "$HOME/.local/bin" ] && [ ! -L "$HOME/.local/bin" ]'
check "~/.config is a real directory" sh -c '[ -d "$HOME/.config" ] && [ ! -L "$HOME/.config" ]'

echo
echo "=== 4. mise conf.d holds the profile"
check "~/.config/mise/config.toml" is_link_to "$HOME/.config/mise/config.toml" mise/.config/mise/config.toml
check "conf.d/00-core.toml" is_link_to "$HOME/.config/mise/conf.d/00-core.toml" profiles/00-core.toml
check "conf.d/20-editor.toml" is_link_to "$HOME/.config/mise/conf.d/20-editor.toml" profiles/20-editor.toml
check "no work profile by default" test ! -e "$HOME/.config/mise/conf.d/30-work.toml"
check "~/.config/mise is a real directory" sh -c '[ -d "$HOME/.config/mise" ] && [ ! -L "$HOME/.config/mise" ]'

echo
echo "=== 4b. an old stow-style link gets repaired"
# stow linked ~/.config/mise straight into the repo. conf.d written through
# that link would land inside the checkout.
rm -rf "$HOME/.config/mise"
ln -s "$HOME/dotfiles/mise/.config/mise" "$HOME/.config/mise"
./bootstrap.sh link -o mise >/dev/null 2>&1
check "~/.config/mise is real again" sh -c '[ -d "$HOME/.config/mise" ] && [ ! -L "$HOME/.config/mise" ]'
check "no conf.d inside the repo" test ! -e "$HOME/dotfiles/mise/.config/mise/conf.d"
check "conf.d links point at profiles" is_link_to "$HOME/.config/mise/conf.d/00-core.toml" profiles/00-core.toml

echo
echo "=== 5. windows packages stay off a linux host"
check "no ~/.glzr" test ! -e "$HOME/.glzr"
check "no ~/komorebi.json" test ! -e "$HOME/komorebi.json"

echo
echo "=== 6. seeds exist and hold no secret"
check "hosts.sh" test -f "$HOME/.config/environments/hosts.sh"
check "paths.sh" test -f "$HOME/.config/environments/paths.sh"
check "langs.sh" test -f "$HOME/.config/environments/langs.sh"
check "~/.env.json" test -f "$HOME/.env.json"
check "no token leaked into the seed" sh -c '! grep -qE "glpat-|sk-|bgpat-" "$HOME/.env.json"'
check "CC points at zcc on a host with no gcc" grep -q zcc "$HOME/.config/environments/langs.sh"

echo
echo "=== 6b. the env template names GITHUB_TOKEN"
check "GITHUB_TOKEN key exists" grep -q GITHUB_TOKEN "$HOME/.env.json"

echo
echo "=== 7. the link phase is idempotent"
./bootstrap.sh link >/tmp/second.log 2>&1
check "a second run reports no conflict" sh -c '! grep -q "exists" /tmp/second.log'
check "a second run creates no link" sh -c '! grep -qE "ok +~.* linked" /tmp/second.log'
check "a second run only skips" grep -q "skip ~/.zshenv" /tmp/second.log

echo
echo "=== 8. the conflict policy"
rm -f "$HOME/.wezterm.lua"
echo "-- a file the host already had" >"$HOME/.wezterm.lua"
./bootstrap.sh link -o wezterm >/tmp/conflict.log 2>&1 || true
check "a conflict is reported, not overwritten" grep -q "exists" /tmp/conflict.log
check "the host file survives" test ! -L "$HOME/.wezterm.lua"
./bootstrap.sh link -o wezterm --backup >/dev/null 2>&1
check "--backup links the repo file" is_link_to "$HOME/.wezterm.lua" dotfiles/wezterm/.wezterm.lua
# $HOME has to reach the inner shell, so the quotes stay single.
# shellcheck disable=SC2016
check "--backup keeps a copy" sh -c 'ls "$HOME"/.wezterm.lua.bak.* >/dev/null 2>&1'
rm -f "$HOME"/.wezterm.lua.bak.*

echo
echo "=== 9. the profile flag"
./bootstrap.sh link --profile core >/dev/null 2>&1
check "core keeps 00-core.toml" test -L "$HOME/.config/mise/conf.d/00-core.toml"
check "core drops 20-editor.toml" test ! -e "$HOME/.config/mise/conf.d/20-editor.toml"
./bootstrap.sh link --profile work >/dev/null 2>&1
check "work adds 30-work.toml" test -L "$HOME/.config/mise/conf.d/30-work.toml"
check "every conf.d link resolves" sh -c 'for l in "$HOME"/.config/mise/conf.d/*; do [ -e "$l" ] || exit 1; done'

echo
echo "=== 10. zsh starts with no tool installed"
if zsh -ic 'echo ZSH_STARTED' >/tmp/zsh.log 2>&1; then
  check "zsh reaches the prompt" grep -q ZSH_STARTED /tmp/zsh.log
else
  printf 'FAIL  zsh exited non-zero\n'
  cat /tmp/zsh.log
  FAILED=$((FAILED + 1))
fi
check "no brew error" sh -c '! grep -qi "brew.*not found\|No such file.*brew" /tmp/zsh.log'
check "no mise error" sh -c '! grep -qi "mise.*No such file" /tmp/zsh.log'

echo
echo "=== 11. doctor runs"
./bootstrap.sh doctor >/tmp/doctor.log 2>&1 || true
check "doctor reports no broken link" sh -c '! grep -q "is broken" /tmp/doctor.log'
check "doctor names the missing tools" grep -q "nvim is missing" /tmp/doctor.log

echo
# The tilde in a check description is display text, not a path.
# shellcheck disable=SC2088
echo "=== 12. uninstall"
./bootstrap.sh uninstall >/dev/null 2>&1
check "~/.zshenv is gone" test ! -e "$HOME/.zshenv"
check "~/.config/nvim is gone" test ! -e "$HOME/.config/nvim"
check "the host files stay" test -f "$HOME/.config/environments/hosts.sh"

echo
if [ "$FAILED" -gt 0 ]; then
  echo "RESULT: $FAILED check(s) failed"
  exit 1
fi
echo "RESULT: every check passed"
