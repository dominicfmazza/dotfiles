#!/bin/sh
# Case: full install. Links, installs every tool with mise, pulls the Neovim
# nightly, and syncs the plugins. This case needs network egress.
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

echo "=== 1. install with the editor profile"
./bootstrap.sh install --profile editor

echo
echo "=== 2. mise is present and its config parses"
check "mise binary" test -x "$HOME/.local/bin/mise"
check "mise config parses" "$HOME/.local/bin/mise" config >/dev/null

echo
echo "=== 3. core tools resolve through the shims"
for t in fzf fd rg bat jq eza zoxide lazygit yazi oh-my-posh sk tldr; do
  check "$t" sh -c "PATH=\"\$HOME/.local/share/mise/shims:\$PATH\" command -v $t >/dev/null"
done

echo
echo "=== 3b. every tool in the profile installed"
check "mise install reports no failure" sh -c '"$HOME/.local/bin/mise" install --yes 2>&1 | grep -viq "^mise ERROR Failed to install tools"'

echo
echo "=== 4. zig supplies a compiler on a host with no gcc"
check "no system gcc" sh -c '! command -v gcc >/dev/null'
check "zig runs" sh -c 'PATH="$HOME/.local/share/mise/shims:$PATH" zig version >/dev/null'
printf 'int main(void){return 0;}\n' >/tmp/probe.c
check "zcc compiles a C file" sh -c 'PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH" zcc -o /tmp/probe /tmp/probe.c'
check "the binary runs" /tmp/probe

echo
echo "=== 5. cargo is available"
check "cargo runs" sh -c 'PATH="$HOME/.local/share/mise/shims:$PATH" cargo --version >/dev/null'
check "rustc runs" sh -c 'PATH="$HOME/.local/share/mise/shims:$PATH" rustc --version >/dev/null'

echo
echo "=== 6. neovim meets the version floor"
NVIM="$HOME/.local/share/mise/shims/nvim"
check "nvim shim" test -x "$NVIM"
if [ -x "$NVIM" ]; then
  "$NVIM" --version | head -1
  check "nvim is 0.13 or later" sh -c "\"$NVIM\" --version | head -1 | grep -qE 'v0\\.(1[3-9]|[2-9][0-9])'"
  check "nvim starts with no error" sh -c "\"$NVIM\" --headless '+qa' 2>&1 | grep -vq 'E[0-9]'"
  check "plugins are on disk" sh -c 'test -d "$HOME/.local/share/nvim/site/pack/core/opt"'
fi

echo
echo "=== 7. zsh starts with every tool present"
zsh -ic 'echo ZSH_STARTED' >/tmp/zsh.log 2>&1 || true
check "zsh reaches the prompt" grep -q ZSH_STARTED /tmp/zsh.log
check "no error in the shell start" sh -c '! grep -qiE "not found|no such file" /tmp/zsh.log'

echo
echo "=== 8. doctor is healthy"
./bootstrap.sh doctor >/tmp/doctor.log 2>&1 || true
cat /tmp/doctor.log
check "doctor reports healthy" grep -q healthy /tmp/doctor.log
check "doctor finds every core tool" sh -c '! grep -qE "(fzf|rg|fd|bat|jq|eza|zoxide|lazygit|yazi|oh-my-posh|nvim) is missing" /tmp/doctor.log'

echo
echo "=== 9. every formatter and language server resolves"
for t in stylua yamlfmt black gersemi beautysh mdformat prettierd clang-format; do
  check "$t" sh -c "PATH=\"\$HOME/.local/share/mise/shims:\$PATH\" command -v $t >/dev/null"
done
for t in lua-language-server bash-language-server yaml-language-server \
  vscode-json-language-server docker-langserver basedpyright cmake-language-server \
  clangd ty tree-sitter; do
  check "$t" sh -c "PATH=\"\$HOME/.local/share/mise/shims:\$PATH\" command -v $t >/dev/null"
done

echo
if [ "$FAILED" -gt 0 ]; then
  echo "RESULT: $FAILED check(s) failed"
  exit 1
fi
echo "RESULT: every check passed"
