# Shared helpers for bootstrap.sh. POSIX sh only.
#
# Every function keeps its variables under an underscore prefix. POSIX sh has
# no `local`, so a plain name would leak between a caller and a callee.
# shellcheck shell=sh

# ---------------------------------------------------------------- output ----

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RED=$(printf '\033[31m')
  C_GRN=$(printf '\033[32m')
  C_YEL=$(printf '\033[33m')
  C_BLU=$(printf '\033[34m')
  C_DIM=$(printf '\033[2m')
  C_OFF=$(printf '\033[0m')
else
  C_RED='' C_GRN='' C_YEL='' C_BLU='' C_DIM='' C_OFF=''
fi

FAIL_COUNT=0
WARN_COUNT=0

say() { printf '%s\n' "$*"; }
info() { printf '%s==>%s %s\n' "$C_BLU" "$C_OFF" "$*"; }
ok() { printf '  %sok%s   %s\n' "$C_GRN" "$C_OFF" "$*"; }
skip() { printf '  %sskip%s %s\n' "$C_DIM" "$C_OFF" "$*"; }
warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  printf '  %swarn%s %s\n' "$C_YEL" "$C_OFF" "$*" >&2
}
fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf '  %sfail%s %s\n' "$C_RED" "$C_OFF" "$*" >&2
}
die() {
  printf '%serror%s %s\n' "$C_RED" "$C_OFF" "$*" >&2
  exit 1
}
act() {
  # Report an action. Run it unless DRY_RUN is set.
  if [ "${DRY_RUN:-0}" = 1 ]; then
    printf '  %sdry%s  %s\n' "$C_DIM" "$C_OFF" "$*"
    return 0
  fi
  "$@"
}

have() { command -v "$1" >/dev/null 2>&1; }

pretty() {
  case "$1" in
    "$HOME"/*) printf '~%s\n' "${1#"$HOME"}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

# ---------------------------------------------------------------- detect ----

detect_platform() {
  # Prints one of: wsl linux darwin windows unknown
  #
  # A container on WSL shares the WSL kernel, so /proc/version alone is not
  # proof. A real WSL session also has the interop marker or wslpath.
  case "$(uname -s 2>/dev/null || echo unknown)" in
    Linux)
      if [ -n "${WSL_DISTRO_NAME:-}" ] || [ -d /run/WSL ] \
        || { [ -e /proc/sys/fs/binfmt_misc/WSLInterop ] && [ -d /mnt/c ]; }; then
        echo wsl
      else
        echo linux
      fi
      ;;
    Darwin) echo darwin ;;
    MINGW* | MSYS* | CYGWIN*) echo windows ;;
    *) echo unknown ;;
  esac
}

detect_arch() {
  case "$(uname -m 2>/dev/null)" in
    x86_64 | amd64) echo x64 ;;
    aarch64 | arm64) echo arm64 ;;
    *) uname -m ;;
  esac
}

win_home() {
  # Windows user profile as a path this shell can write. Empty on failure.
  # The result is cached, because the cmd.exe probe is slow.
  if [ -n "${WIN_HOME_CACHE:-}" ]; then
    [ "$WIN_HOME_CACHE" = none ] && return 1
    printf '%s\n' "$WIN_HOME_CACHE"
    return 0
  fi

  WIN_HOME_CACHE=none
  if [ -n "${USERPROFILE:-}" ]; then
    WIN_HOME_CACHE=$USERPROFILE
  elif [ "${PLATFORM:-}" = wsl ] && have wslpath && have cmd.exe; then
    # cmd.exe reads stdin, so keep it away from a caller's input stream.
    _wh_raw=$(cd /mnt/c 2>/dev/null && cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null </dev/null | tr -d '\r')
    if [ -n "$_wh_raw" ]; then
      _wh_path=$(wslpath -u "$_wh_raw" 2>/dev/null) || _wh_path=''
      [ -n "$_wh_path" ] && WIN_HOME_CACHE=$_wh_path
    fi
  fi

  [ "$WIN_HOME_CACHE" = none ] && return 1
  printf '%s\n' "$WIN_HOME_CACHE"
}

# Compare two dotted versions. Returns 0 when $1 >= $2.
version_ge() {
  [ "$1" = "$2" ] && return 0
  _vg_low=$(printf '%s\n%s\n' "$1" "$2" | sort -t. -k1,1n -k2,2n -k3,3n | head -1)
  [ "$_vg_low" = "$2" ]
}

tool_version() {
  # Prints the first dotted number in the tool's version output.
  "$@" 2>&1 | tr ' ' '\n' | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1
}

# ------------------------------------------------------------------ paths ----

canon() {
  # Absolute path with every '..' and symlinked parent resolved.
  _cn_dir=$(dirname -- "$1")
  _cn_base=$(basename -- "$1")
  _cn_dir=$(cd -P -- "$_cn_dir" 2>/dev/null && pwd -P) || return 1
  case "$_cn_base" in
    /) printf '/\n' ;;
    *) printf '%s/%s\n' "${_cn_dir%/}" "$_cn_base" ;;
  esac
}

link_target() {
  # Absolute, canonical path a symlink points at.
  _lt_raw=$(readlink -- "$1") || return 1
  case "$_lt_raw" in
    /*) canon "$_lt_raw" ;;
    *) canon "$(dirname -- "$1")/$_lt_raw" ;;
  esac
}

owned_by_repo() {
  # True when $1 is a symlink that resolves into the dotfiles repo.
  [ -L "$1" ] || return 1
  _ob_t=$(link_target "$1") || return 1
  case "$_ob_t" in
    "$REPO_ROOT"/*) return 0 ;;
    *) return 1 ;;
  esac
}

# ------------------------------------------------------------------ links ----

same_content() {
  # True when two files hold identical bytes. cmp is absent on a minimal
  # image such as RHEL UBI, so fall back to a checksum.
  if have cmp; then
    cmp -s "$1" "$2" 2>/dev/null
    return $?
  fi
  for _sc_sum in md5sum sha256sum shasum; do
    if have "$_sc_sum"; then
      _sc_a=$("$_sc_sum" <"$1" 2>/dev/null) || return 1
      _sc_b=$("$_sc_sum" <"$2" 2>/dev/null) || return 1
      [ "$_sc_a" = "$_sc_b" ]
      return $?
    fi
  done
  return 1
}

is_distro_default() {
  # True when $1 is a pristine copy of the distribution skeleton file.
  # A new account gets /etc/skel copied into it, so RHEL puts a default
  # .zshrc and .bashrc in every home. Those are not user content: replacing
  # one loses nothing, and refusing to link over it blocks the install.
  _dd_name=$(basename "$1")
  for _dd_skel in /etc/skel "${DOTFILES_SKEL_DIR:-}"; do
    [ -n "$_dd_skel" ] || continue
    [ -f "$_dd_skel/$_dd_name" ] || continue
    if same_content "$1" "$_dd_skel/$_dd_name"; then
      return 0
    fi
  done
  return 1
}

make_link() {
  # make_link SRC DST. Applies the conflict policy in $CONFLICT.
  _ml_src=$1
  _ml_dst=$2

  if owned_by_repo "$_ml_dst"; then
    if [ "$(link_target "$_ml_dst")" = "$(canon "$_ml_src")" ]; then
      skip "$(pretty "$_ml_dst") (linked)"
      return 0
    fi
    act rm -f "$_ml_dst"
    act ln -s "$_ml_src" "$_ml_dst"
    ok "$(pretty "$_ml_dst") relinked"
    return 0
  fi

  # A pristine /etc/skel copy is not user content. Replace it silently.
  if [ -f "$_ml_dst" ] && [ ! -L "$_ml_dst" ] && is_distro_default "$_ml_dst"; then
    act rm -f "$_ml_dst"
    act ln -s "$_ml_src" "$_ml_dst"
    ok "$(pretty "$_ml_dst") linked (replaced the distribution default)"
    return 0
  fi

  if [ -e "$_ml_dst" ] || [ -L "$_ml_dst" ]; then
    case "${CONFLICT:-report}" in
      backup)
        act mv "$_ml_dst" "$_ml_dst.bak.$RUN_STAMP"
        act ln -s "$_ml_src" "$_ml_dst"
        ok "$(pretty "$_ml_dst") linked. Old copy: $(basename "$_ml_dst").bak.$RUN_STAMP"
        ;;
      adopt)
        act rm -rf "$_ml_src"
        act mv "$_ml_dst" "$_ml_src"
        act ln -s "$_ml_src" "$_ml_dst"
        ok "$(pretty "$_ml_dst") adopted into the repo"
        ;;
      force)
        act rm -rf "$_ml_dst"
        act ln -s "$_ml_src" "$_ml_dst"
        ok "$(pretty "$_ml_dst") linked. Old copy deleted."
        ;;
      *)
        warn "$(pretty "$_ml_dst") exists. Use --backup, --adopt, or --force."
        ;;
    esac
    return 0
  fi

  act mkdir -p "$(dirname "$_ml_dst")"
  act ln -s "$_ml_src" "$_ml_dst"
  ok "$(pretty "$_ml_dst") linked"
}

link_tree() {
  # link_tree SRC_DIR DST_DIR [fold|nofold] [exclude names] [keep-real file]
  #
  # fold   link the deepest free path, the way GNU stow folds a directory.
  # nofold create every directory for real and link only the files.
  #
  # "keep-real file" names a file with one absolute destination path per
  # line. Each path stays a real directory. Two packages that share a
  # directory, such as ~/.config, must not let the first one link the path.
  #
  # The walk uses the positional parameters as a queue, so it needs no
  # recursion and leaks no variable.
  _lt_src=${1%/}
  _lt_dst=${2%/}
  _lt_mode=${3:-'fold'}
  _lt_skip=${4:-}
  _lt_real=${5:-}

  [ -d "$_lt_src" ] || {
    warn "missing source $_lt_src"
    return 0
  }

  set -- "$_lt_src"
  while [ $# -gt 0 ]; do
    _lt_cur=$1
    shift
    _lt_rel=${_lt_cur#"$_lt_src"}

    for _lt_entry in "$_lt_cur"/* "$_lt_cur"/.[!.]*; do
      [ -e "$_lt_entry" ] || [ -L "$_lt_entry" ] || continue
      _lt_name=${_lt_entry##*/}

      case "$_lt_name" in
        .git | .gitignore | .gitkeep | .gitmodules) continue ;;
      esac
      for _lt_x in $_lt_skip; do
        [ "$_lt_name" = "$_lt_x" ] && continue 2
      done

      _lt_target="$_lt_dst$_lt_rel/$_lt_name"

      if [ -d "$_lt_entry" ] && [ ! -L "$_lt_entry" ]; then
        _lt_keep=0
        [ "$_lt_mode" = 'nofold' ] && _lt_keep=1
        if [ -n "$_lt_real" ] && [ -f "$_lt_real" ] \
          && grep -Fxq -- "$_lt_target" "$_lt_real"; then
          _lt_keep=1
        fi

        if [ "$_lt_keep" = 1 ]; then
          # A path that must stay real, but an earlier install linked it
          # into the repo. Writing through that link would put host state
          # inside the checkout, so replace the link with a real directory.
          if [ -L "$_lt_target" ] && owned_by_repo "$_lt_target"; then
            act rm -f "$_lt_target"
            ok "$(pretty "$_lt_target") is a real directory again"
          fi
          [ -d "$_lt_target" ] || act mkdir -p "$_lt_target"
          set -- "$@" "$_lt_entry"
        elif [ -d "$_lt_target" ] && [ ! -L "$_lt_target" ]; then
          set -- "$@" "$_lt_entry"
        else
          make_link "$_lt_entry" "$_lt_target"
        fi
      else
        make_link "$_lt_entry" "$_lt_target"
      fi
    done
  done
}

unlink_tree() {
  # Remove every symlink under $1, down to depth 6, that this repo owns.
  [ -d "$1" ] || return 0
  find "$1" -maxdepth 6 -type l -print 2>/dev/null >"${TMPDIR:-/tmp}/dotlinks.$$" || true
  while read -r _ut_l; do
    if owned_by_repo "$_ut_l"; then
      act rm -f "$_ut_l"
      ok "removed $(pretty "$_ut_l")"
    fi
  done <"${TMPDIR:-/tmp}/dotlinks.$$"
  rm -f "${TMPDIR:-/tmp}/dotlinks.$$"
}

# ---------------------------------------------------------------- fetch -----

home_fstype() {
  stat -f -c %T "$HOME" 2>/dev/null || echo unknown
}

home_is_remote() {
  case "$(home_fstype)" in
    nfs | nfs4 | smb2 | smb | cifs | fuseblk | afs | 9p | lustre | gpfs) return 0 ;;
    *) return 1 ;;
  esac
}

fetch() {
  # fetch URL OUT
  if have curl; then
    act curl -fsSL --proto '=https' --tlsv1.2 -o "$2" "$1"
  elif have wget; then
    act wget -qO "$2" "$1"
  else
    die "no curl and no wget"
  fi
}

tls_probe() {
  # Report whether HTTPS to github.com works. A proxy that intercepts TLS
  # breaks every download until the host trusts the proxy CA.
  have curl || return 0
  curl -fsS --max-time 20 -o /dev/null https://github.com 2>/dev/null && return 0

  warn "HTTPS to github.com failed. A proxy may intercept TLS."
  say "  ${C_DIM}Point the tools at the corporate CA bundle:$C_OFF"
  say "  ${C_DIM}  export SSL_CERT_FILE=/path/to/ca-bundle.pem$C_OFF"
  say "  ${C_DIM}  export CURL_CA_BUNDLE=\$SSL_CERT_FILE$C_OFF"
  say "  ${C_DIM}  export NODE_EXTRA_CA_CERTS=\$SSL_CERT_FILE$C_OFF"
  say "  ${C_DIM}  export CARGO_HTTP_CAINFO=\$SSL_CERT_FILE$C_OFF"
  return 1
}

seed_file() {
  # seed_file TEMPLATE DEST. Never overwrites.
  if [ -e "$2" ]; then
    skip "$(pretty "$2") (kept)"
    return 0
  fi
  act mkdir -p "$(dirname "$2")"
  act cp "$1" "$2"
  ok "$(pretty "$2") seeded"
}
