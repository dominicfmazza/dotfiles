#!/bin/sh
# zig-target.sh: print the `zig cc` -target flags for this host, or nothing.
#
# `zig cc` links against the newest glibc it knows by default. On an old host
# such as RHEL 9 (glibc 2.34), a binary or a .so built that way needs a glibc
# the host does not have. Neovim then fails to load a treesitter parser with a
# "version `GLIBC_2.xx' not found" error.
#
# The fix pins the target glibc to the host glibc. Every artifact then links
# against a glibc the host has.
#
# Override the version with ZIG_GLIBC_TARGET, for example 2.34. Set it to
# "none" to skip the target flag and use the zig default.
#
# The output is a full flag string, empty when no target applies. A caller
# reads it into a variable and passes it to zig cc.

zig_glibc_version() {
  # Print the host glibc version, for example 2.34. Empty on failure.
  if [ -n "${ZIG_GLIBC_TARGET:-}" ]; then
    printf '%s\n' "$ZIG_GLIBC_TARGET"
    return 0
  fi

  # getconf is the exact source and needs no parsing of a version string.
  _v=$(getconf GNU_LIBC_VERSION 2>/dev/null | awk '{print $2}')
  if [ -n "$_v" ]; then
    printf '%s\n' "$_v"
    return 0
  fi

  # ldd prints the version on its first line, for example "ldd ... 2.34".
  _v=$(ldd --version 2>/dev/null | head -1 | awk '{print $NF}')
  [ -n "$_v" ] && printf '%s\n' "$_v"
}

zig_target_flags() {
  # Print the -target flag for this host, or nothing.
  _glibc=$(zig_glibc_version)
  [ -z "$_glibc" ] && return 0
  [ "$_glibc" = none ] && return 0

  case "$(uname -m 2>/dev/null)" in
    x86_64 | amd64) _zt_arch=x86_64 ;;
    aarch64 | arm64) _zt_arch=aarch64 ;;
    *) return 0 ;;
  esac

  printf '%s\n' "-target ${_zt_arch}-linux-gnu.${_glibc}"
}
