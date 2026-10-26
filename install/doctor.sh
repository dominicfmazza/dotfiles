# doctor.sh: check an existing install and report. It changes nothing.
# shellcheck shell=sh
. "$DOTFILES_REPO/install/env.sh"
cd "$HOME"

var() { "$MISE_BIN" config get -f "$REPO_ROOT/mise.toml" "vars.$1" 2>/dev/null; }

check_bin() {
  # A doctor run from a plain sh has no mise on PATH, so look in the shims.
  if p=$(command -v "$1" 2>/dev/null); then
    ok "$1 $(tool_version "$1" --version) ($p)"
  elif [ -x "$XDG_DATA_HOME/mise/shims/$1" ]; then
    ok "$1 $(tool_version "$XDG_DATA_HOME/mise/shims/$1" --version) (shim)"
  else
    warn "$1 is missing"
  fi
}

info "Doctor on $PLATFORM/$ARCH"

say "  ${C_DIM}links$C_OFF"
broken=0
for d in "$HOME" "$HOME/.local/bin" "$XDG_CONFIG_HOME" "$XDG_CONFIG_HOME/mise/conf.d"; do
  [ -d "$d" ] || continue
  for l in "$d"/* "$d"/.[!.]*; do
    owned_by_repo "$l" || continue
    if [ -e "$l" ]; then ok "$(pretty "$l")"; else
      fail "$(pretty "$l") is broken"
      broken=1
    fi
  done
done
[ "$broken" = 0 ] && ok "no broken link"

say "  ${C_DIM}host files$C_OFF"
seeds=$(manifest seed)
while read -r tpl dst platforms; do
  on_platform "${platforms:-all}" || continue
  f=$(expand_path "$dst")
  if [ -f "$f" ]; then ok "$(pretty "$f")"; else warn "$(pretty "$f") is missing"; fi
done <<EOS
$seeds
EOS

say "  ${C_DIM}filesystem$C_OFF"
fs=$(home_fstype)
if home_is_remote; then
  ok "\$HOME is on $fs"
  # Read the values back from zsh, to prove that .zshenv sets them.
  croot=$(zsh -c 'printf %s "${DOTFILES_CACHE_ROOT:-}"' 2>/dev/null)
  if [ -n "$croot" ]; then ok "cache root $croot"; else fail "the home is remote but zsh set no cache root. Check ~/.zshenv."; fi
  case "$(zsh -c 'printf %s "${MISE_DATA_DIR:-}"' 2>/dev/null)" in
  "$HOME"/*) ok "mise installs stay on \$HOME" ;;
  '') warn "MISE_DATA_DIR is unset. mise uses its default." ;;
  *) fail "MISE_DATA_DIR is not on \$HOME. Installs must stay on \$HOME." ;;
  esac
else
  ok "\$HOME is on $fs. No cache redirect is needed."
fi

say "  ${C_DIM}secrets$C_OFF"
if out=$(sh "$REPO_ROOT/install/scan-secrets.sh" 2>&1); then
  ok "no credential in the repo"
else
  fail "the repo holds a credential or an internal hostname"
  printf '%s\n' "$out" | sed 's/^/    /' >&2
fi
if [ -e "$REPO_ROOT/.git/hooks/pre-commit" ]; then ok "the pre-commit scan hook is installed"; else warn "no pre-commit hook. Run: mise run link"; fi

say "  ${C_DIM}tools$C_OFF"
check_bin zsh
check_bin git
if [ -x "$MISE_BIN" ]; then
  ok "mise $("$MISE_BIN" --version 2>/dev/null | head -1)"
  # mise reports each tool in the active profile that is not installed.
  missing=$("$MISE_BIN" ls --missing --no-header 2>/dev/null | awk '{print $1}' | tr '\n' ' ')
  if [ -z "$missing" ]; then ok "every tool in the profile is installed"; else warn "not installed: $missing"; fi
else
  fail "mise is missing"
fi
for t in nvim fzf rg fd bat jq eza zoxide lazygit yazi oh-my-posh; do check_bin "$t"; done

if have clang; then
  ok "clang $(tool_version clang --version)"
else
  fail "clang is missing. tree-sitter and the parsers will not build."
fi

# A tree-sitter binary that needs a newer glibc still resolves on PATH.
# Only a real run shows the loader error.
ts=$(command -v tree-sitter 2>/dev/null || true)
[ -z "$ts" ] && [ -x "$XDG_DATA_HOME/mise/shims/tree-sitter" ] && ts="$XDG_DATA_HOME/mise/shims/tree-sitter"
ts_min=$(var tree_sitter_min || echo 0.26.1)
if [ -z "$ts" ]; then
  warn "the tree-sitter CLI is missing. Treesitter parsers will not build."
elif ! tsout=$("$ts" --version 2>&1); then
  fail "the tree-sitter CLI does not run: $(printf '%s' "$tsout" | head -1)"
  case "$tsout" in *GLIBC*) say "  ${C_DIM}Run: mise install -y cargo:tree-sitter-cli$C_OFF" ;; esac
else
  tsv=$(printf '%s' "$tsout" | tool_version cat)
  if version_ge "$tsv" "$ts_min"; then ok "tree-sitter $tsv builds parsers"; else fail "tree-sitter $tsv is below the $ts_min floor"; fi
fi

nv=$("$MISE_BIN" which nvim 2>/dev/null || command -v nvim 2>/dev/null || true)
nv_min=$(var nvim_min || echo 0.13)
if [ -n "$nv" ]; then
  v=$(tool_version "$nv" --version)
  if version_ge "$v" "$nv_min"; then ok "nvim $v meets the $nv_min floor"; else fail "nvim $v is below the $nv_min floor"; fi
fi

case "$PLATFORM" in
linux | darwin)
  say "  ${C_DIM}desktop$C_OFF"
  if ls "$XDG_DATA_HOME/fonts"/HackNerdFont-*.ttf "$HOME/Library/Fonts"/HackNerdFont-*.ttf >/dev/null 2>&1; then
    ok "Hack Nerd Font is installed"
  else
    warn "Hack Nerd Font is missing. Use --profile full and run: mise run install"
  fi
  check_bin kitty
  ;;
esac

say "  ${C_DIM}remote$C_OFF"
check_bin mutagen
check_bin python3
if grep -qF '# dotfiles: shared SSH settings' "$HOME/.ssh/config" 2>/dev/null; then
  ok "$(pretty "$HOME/.ssh/config") includes the shared settings"
else
  warn "$(pretty "$HOME/.ssh/config") does not include the shared settings. Run: mise run link"
fi
if have tmux; then
  if infocmp tmux-256color >/dev/null 2>&1; then
    ok "the tmux-256color terminfo is present"
  else
    warn "no tmux-256color terminfo. tmux falls back to xterm-256color."
  fi
fi
if have oob; then
  if out=$(oob ping 2>&1); then
    ok "oob: $(printf '%s' "$out" | awk '/^(mode|status|server):/ { printf "%s ", $0 }')"
  else
    warn "oob: $(printf '%s' "$out" | awk '/^status:/ { print }')"
  fi
else
  warn "oob is not on PATH. Run: mise run link"
fi

if [ "$PLATFORM" = darwin ]; then
  say "  ${C_DIM}window manager$C_OFF"
  for app in AeroSpace Übersicht; do
    if [ -d "/Applications/$app.app" ]; then ok "$app is installed"; else warn "$app is missing. Run: mise run install"; fi
  done
  if [ -d "$HOME/Library/Application Support/Übersicht/widgets/simple-bar/.git" ]; then
    ok "simple-bar is present"
  else
    warn "simple-bar is missing. Run: mise run install"
  fi
fi

say ''
if [ "$FAIL_COUNT" -gt 0 ]; then
  say "${C_RED}$FAIL_COUNT problem(s)${C_OFF}, ${C_YEL}$WARN_COUNT warning(s)${C_OFF}"
  exit 1
fi
say "${C_GRN}healthy${C_OFF}, ${C_YEL}$WARN_COUNT warning(s)${C_OFF}"
