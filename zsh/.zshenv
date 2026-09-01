# .zshenv runs for EVERY zsh: login, interactive, and script.
#
# Every zsh file lives in $HOME, so ZDOTDIR is not set. A ZDOTDIR changes
# where zsh looks for .zprofile and .zshrc, and setting it needs a
# $HOME/.zshenv anyway, because zsh reads $ZDOTDIR/.zshenv before anything
# else. An earlier version set ZDOTDIR in .zprofile, which a non-login
# interactive shell never reads, so that shell loaded no .zshrc at all.
#
# Keep this file cheap. Every `zsh -c` pays for it.

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}

# ------------------------------------------------------------- cache root ----
#
# A network home breaks any tool that locks a cache file. NFS without a lock
# daemon rejects flock, and the kernel returns EBADF, which a tool reports as
# "Bad file descriptor (os error 9)".
#
# A cache is machine-local and rebuildable, so move it to local disk when the
# home cannot hold a lock. Tool INSTALLS stay on the home: those are large and
# must survive a reboot. Only the cache is transient. On Amazon RES the
# instance is replaced often, so a lost cache costs one version lookup per
# tool, not a re-download.
#
# /var/tmp is disk-backed and large. /tmp is usually tmpfs, so a
# multi-gigabyte npm cache would consume RAM.
#
# Detection has two parts. A filesystem name catches the common cases with no
# I/O. A real flock attempt catches the rest, and its answer is cached on the
# home, so only the first shell after a reboot pays for the probe.

if [[ -z ${DOTFILES_CACHE_ROOT:-} ]]; then
  _home_needs_local_cache=0

  case "${$(stat -f -c %T "$HOME" 2>/dev/null):-unknown}" in
    nfs | nfs4 | smb2 | smb | cifs | fuseblk | afs | 9p | lustre | gpfs)
      _home_needs_local_cache=1
      ;;
    *)
      # An unusual filesystem may still reject a lock. Probe once and reuse
      # the answer. The marker holds the boot id, so it expires on a reboot.
      _lock_marker=$HOME/.cache/.dotfiles-lock-ok
      _boot_id=$(< /proc/sys/kernel/random/boot_id) 2>/dev/null
      if [[ -r $_lock_marker && $(< $_lock_marker) == $_boot_id ]]; then
        : # the home held a lock earlier this boot
      else
        [[ -d $HOME/.cache ]] || mkdir -p "$HOME/.cache" 2>/dev/null
        _lock_probe=$HOME/.cache/.dotfiles-lock-probe
        # zsystem flock needs the file to exist, so create it first.
        : >>"$_lock_probe" 2>/dev/null
        if zmodload zsh/system 2>/dev/null \
          && ( zsystem flock -t 0 "$_lock_probe" ) 2>/dev/null; then
          print -r -- "$_boot_id" >| "$_lock_marker" 2>/dev/null
        else
          _home_needs_local_cache=1
        fi
        rm -f "$_lock_probe" 2>/dev/null
        unset _lock_probe
      fi
      unset _lock_marker _boot_id
      ;;
  esac

  if (( _home_needs_local_cache )); then
    for _cache_base in /var/tmp /tmp "$XDG_RUNTIME_DIR"; do
      [[ -n $_cache_base && -d $_cache_base && -w $_cache_base ]] || continue
      DOTFILES_CACHE_ROOT="$_cache_base/${USER:-$UID}-cache"
      break
    done
    unset _cache_base
  fi
  unset _home_needs_local_cache
fi

if [[ -n ${DOTFILES_CACHE_ROOT:-} ]]; then
  export DOTFILES_CACHE_ROOT
  [[ -d $DOTFILES_CACHE_ROOT ]] || mkdir -p -m 700 "$DOTFILES_CACHE_ROOT" 2>/dev/null

  export XDG_CACHE_HOME="$DOTFILES_CACHE_ROOT"

  # mise keeps version lists and lock files in the cache. Its installs and
  # shims stay on the home, so a reboot costs one version lookup per tool,
  # not a re-download.
  export MISE_CACHE_DIR="$DOTFILES_CACHE_ROOT/mise"
  export MISE_DATA_DIR="$HOME/.local/share/mise"
  export MISE_STATE_DIR="$HOME/.local/state/mise"

  export npm_config_cache="$DOTFILES_CACHE_ROOT/npm"
  export PNPM_HOME="$DOTFILES_CACHE_ROOT/pnpm"
  export YARN_CACHE_FOLDER="$DOTFILES_CACHE_ROOT/yarn"
  export PIP_CACHE_DIR="$DOTFILES_CACHE_ROOT/pip"
  export GOCACHE="$DOTFILES_CACHE_ROOT/go-build"
  export GOMODCACHE="$DOTFILES_CACHE_ROOT/go-mod"
  export CARGO_TARGET_DIR="$DOTFILES_CACHE_ROOT/cargo-target"
  export ZSH_COMPDUMP="$DOTFILES_CACHE_ROOT/zcompdump"
fi

export UV_CACHE_DIR="$XDG_CACHE_HOME/uv"
