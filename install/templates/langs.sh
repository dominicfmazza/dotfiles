# Compiler and language settings for this host. bootstrap.sh copies this
# file to ~/.config/environments/langs.sh and never overwrites it.
#
# The bootstrap appends a CC and CXX block here when the host has no gcc
# and no clang. The block points at zcc and zxx, which wrap `zig cc`.
#
# zcc and zxx pin the target glibc to the host glibc. A .so they build then
# loads on an old host such as RHEL 9. To override the version, set
# ZIG_GLIBC_TARGET, for example 2.34. Set it to "none" to use the zig default.
# export ZIG_GLIBC_TARGET=2.34
