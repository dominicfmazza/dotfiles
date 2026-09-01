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
check "~/.zshrc" is_link_to "$HOME/.zshrc" dotfiles/zsh/.zshrc
check "~/.zsh_plugins.txt" is_link_to "$HOME/.zsh_plugins.txt" dotfiles/zsh/.zsh_plugins.txt
check "~/.antidote" test -e "$HOME/.antidote/antidote.zsh"
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
echo "=== 4c. the pi package links, but never its secrets"
check "AGENTS.md" is_link_to "$HOME/.pi/agent/AGENTS.md" pi/.pi/agent/AGENTS.md
check "keybindings.json" is_link_to "$HOME/.pi/agent/keybindings.json" pi/.pi/agent/keybindings.json
check "package.json" is_link_to "$HOME/.pi/agent/package.json" pi/.pi/agent/package.json
check "the subagent extension" is_link_to "$HOME/.pi/agent/extensions/subagent/index.ts" subagent/index.ts
check "the implementer agent" is_link_to "$HOME/.pi/agent/agents/implementer.md" agents/implementer.md
check "the commit prompt" is_link_to "$HOME/.pi/agent/prompts/commit.md" prompts/commit.md
check "~/.pi/agent is a real directory" sh -c '[ -d "$HOME/.pi/agent" ] && [ ! -L "$HOME/.pi/agent" ]'

# settings.json must be a copy. pi rewrites it, and a link would dirty the repo.
check "settings.json is a real file" sh -c '[ -f "$HOME/.pi/agent/settings.json" ] && [ ! -L "$HOME/.pi/agent/settings.json" ]'
check "models.json is a real file" sh -c '[ -f "$HOME/.pi/agent/models.json" ] && [ ! -L "$HOME/.pi/agent/models.json" ]'
check "mcp.json is a real file" sh -c '[ -f "$HOME/.config/mcp/mcp.json" ] && [ ! -L "$HOME/.config/mcp/mcp.json" ]'
check "no auth.json is created" test ! -e "$HOME/.pi/agent/auth.json"
check "no agent model is pinned to a provider" sh -c '! grep -rq "^model:" "$HOME/dotfiles/pi/.pi/agent/agents/"'

echo
echo "=== 4d. the secret scan works"
# Every `sh -c` below keeps single quotes on purpose: $HOME must expand in the
# inner shell, not here.
# shellcheck disable=SC2016
check "a clean repo passes" sh -c 'cd "$HOME/dotfiles" && ./install/scan-secrets.sh >/dev/null'

# Plant a token and prove the scan catches it. The literal is assembled at
# run time, so this test file itself never holds a token pattern.
probe_token="gh${probe_p:-p}_0123456789abcdefghij"
printf 'key = "%s"\n' "$probe_token" >"$HOME/dotfiles/leak-probe.txt"
check "a planted token fails the scan" sh -c 'cd "$HOME/dotfiles" && ! ./install/scan-secrets.sh >/dev/null 2>&1'
rm -f "$HOME/dotfiles/leak-probe.txt"

# Plant a pi runtime file and prove the scan catches it.
printf '{}\n' >"$HOME/dotfiles/pi/.pi/agent/auth.json"
check "a planted auth.json fails the scan" sh -c 'cd "$HOME/dotfiles" && ! ./install/scan-secrets.sh >/dev/null 2>&1'
rm -f "$HOME/dotfiles/pi/.pi/agent/auth.json"

# An environment reference and a command reference are safe values.
printf '{ "apiKey": "$SOME_ENV_VAR", "token": "!op read op://v/i" }\n' \
  >"$HOME/dotfiles/safe-probe.json"
check "an env reference does not false-alarm" sh -c 'cd "$HOME/dotfiles" && ./install/scan-secrets.sh >/dev/null'
rm -f "$HOME/dotfiles/safe-probe.json"

echo
echo "=== 4e. the pre-commit hook blocks a real commit"
# The image copy has no .git, so build a throwaway repo and prove that git
# refuses the commit. This is the check that matters: a scan that passes by
# hand but never runs during a commit protects nothing.
HOOKREPO=/tmp/hooktest
rm -rf "$HOOKREPO"
mkdir -p "$HOOKREPO"
cp -r "$HOME/dotfiles/." "$HOOKREPO/" 2>/dev/null || true
rm -rf "$HOOKREPO/.git"
(
  cd "$HOOKREPO"
  git init -q
  git config user.email test@example.invalid
  git config user.name Test
  ./bootstrap.sh link -o pi >/dev/null 2>&1 || true
) >/dev/null 2>&1

check "the hook is a link into the repo" test -L "$HOOKREPO/.git/hooks/pre-commit"

(
  cd "$HOOKREPO"
  git add -A >/dev/null 2>&1
  git commit -qm "initial" >/dev/null 2>&1
) || true
check "a clean commit succeeds" sh -c "cd $HOOKREPO && git log --oneline -1 >/dev/null 2>&1"

# Stage a credential and prove git refuses.
printf '{ "key": "bg%s-5y3c3h25zWavqcPHzUJuH9CV" }\n' "pat" \
  >"$HOOKREPO/pi/.pi/agent/auth.json"
(
  cd "$HOOKREPO"
  git add -f pi/.pi/agent/auth.json >/dev/null 2>&1
)
if (cd "$HOOKREPO" && git commit -qm "must be blocked" >/dev/null 2>&1); then
  printf 'FAIL  the hook let a token through\n'
  FAILED=$((FAILED + 1))
else
  printf 'PASS  the hook blocks a staged token\n'
fi
check "nothing was committed" sh -c "cd $HOOKREPO && [ \"\$(git log --oneline | wc -l)\" = 1 ]"
check "--no-verify still works as the escape hatch" sh -c "cd $HOOKREPO && git commit -qm bypass --no-verify"
rm -rf "$HOOKREPO"
rm -f "$HOME/dotfiles/safe-probe.json"

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
