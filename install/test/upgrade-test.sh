#!/bin/sh
# Reproduce a real-world upgrade on a host that had an OLDER install.
#
# The RES desktop ran an earlier version of these dotfiles, then took the
# zsh layout change. That path is different from a fresh install, and it is
# where a stale link or a stale ZDOTDIR shows up.
#
# Usage: install/test/upgrade-test.sh <old-git-ref>
set -eu

OLD_REF=${1:?usage: upgrade-test.sh <old-git-ref>}
REPO=$(cd "$(dirname "$0")/../.." && pwd -P)
IMAGE=dotfiles-upgrade

cd "$REPO"

# The image needs both the old and the new tree, so ship the whole repo with
# its history and check out each ref inside the container.
cat >/tmp/upgrade.Dockerfile <<'DOCKER'
ARG BASE=registry.access.redhat.com/ubi9/ubi:latest
FROM ${BASE}
RUN dnf -q -y install ca-certificates git gzip tar unzip xz zsh \
    glibc-langpack-en shadow-utils findutils && dnf -q clean all
COPY install/test/ca/ /etc/pki/ca-trust/source/anchors/
RUN update-ca-trust >/dev/null 2>&1 || true
RUN useradd -m -s /bin/bash tester
USER tester
WORKDIR /home/tester
ENV HOME=/home/tester LANG=en_US.UTF-8 TERM=xterm-256color \
    PATH=/home/tester/.local/bin:/usr/local/bin:/usr/bin:/bin
COPY --chown=tester:tester . /home/tester/dotfiles
WORKDIR /home/tester/dotfiles
CMD ["/bin/bash"]
DOCKER

echo "==> Building $IMAGE"
docker build --quiet -f /tmp/upgrade.Dockerfile -t "$IMAGE" . >/dev/null
rm -f /tmp/upgrade.Dockerfile

echo "==> Simulating: old install at $OLD_REF, then upgrade to HEAD"
# -i is required: the script arrives on stdin.
docker run --rm -i -e OLD_REF="$OLD_REF" "$IMAGE" sh -s <<'SCRIPT'
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

NEW_REF=$(git rev-parse HEAD)

# The submodule gitdir pointer does not survive a plain directory copy, and
# a checkout across the layout change cannot rmdir a non-empty submodule
# path. Detach the submodule and keep a copy of antidote for both layouts.
rm -f zsh/.antidote/.git
cp -r zsh/.antidote /tmp/antidote-keep 2>/dev/null || true

echo
echo "--- step 1: install the OLD layout ($OLD_REF)"
git -c advice.detachedHead=false checkout -q "$OLD_REF" 2>/dev/null || true
mkdir -p zsh/.config/zsh
[ -d zsh/.config/zsh/.antidote ] || cp -r /tmp/antidote-keep zsh/.config/zsh/.antidote
./bootstrap.sh link >/dev/null 2>&1 || true
echo "    links after the old install:"
for f in .zshenv .zprofile .zshrc; do
  printf '      %-12s %s\n' "$f" "$([ -L "$HOME/$f" ] && echo link || echo '-')"
done
printf '      %-12s %s\n' ".config/zsh" \
  "$([ -L "$HOME/.config/zsh" ] && echo link || echo '-')"

echo
echo "--- step 2: upgrade to HEAD"
git checkout -q "$NEW_REF" 2>/dev/null || true
rm -rf zsh/.config
[ -d zsh/.antidote ] || cp -r /tmp/antidote-keep zsh/.antidote
./bootstrap.sh link >/tmp/upgrade.log 2>&1 || true
grep -iE 'warn|fail' /tmp/upgrade.log | sed 's/^/    /' || true

echo
echo "--- step 3: the home must hold a working startup file"
# zsh shows the new-user configurator when it finds NONE of these.
have_any=0
for f in .zshenv .zprofile .zshrc .zlogin; do
  [ -e "$HOME/$f" ] && have_any=1
done
check "at least one startup file resolves" test "$have_any" = 1
check ".zshenv resolves" test -e "$HOME/.zshenv"
check ".zshrc resolves" test -e "$HOME/.zshrc"

echo
echo "--- step 4: no stale link survives the move"
stale=0
for l in "$HOME"/.* "$HOME"/.config/*; do
  [ -L "$l" ] || continue
  if [ ! -e "$l" ]; then
    printf '    STALE: %s -> %s\n' "$l" "$(readlink "$l")"
    stale=$((stale + 1))
  fi
done
check "no broken link in the home" test "$stale" = 0
check "no ~/.config/zsh left behind" test ! -e "$HOME/.config/zsh"

echo
echo "--- step 5: the configurator must NOT appear"
out=$(env -i HOME="$HOME" TERM=xterm PATH=/usr/bin:/bin \
  zsh -i -c 'echo SHELL-READY' 2>&1 | tail -3)
case "$out" in
  *zsh-newuser-install* | *"no zsh startup files"*)
    printf 'FAIL  zsh showed the new-user configurator\n'
    FAILED=$((FAILED + 1))
    ;;
  *SHELL-READY*) printf 'PASS  zsh reaches a prompt with no configurator\n' ;;
  *)
    printf 'FAIL  zsh produced unexpected output: %s\n' "$out"
    FAILED=$((FAILED + 1))
    ;;
esac

echo
echo "--- step 6: .zshrc actually loads"
out=$(env -i HOME="$HOME" TERM=xterm PATH=/usr/bin:/bin \
  zsh -i -c 'echo "RC=${ZSH_AUTOSUGGEST_USE_ASYNC:-unset}"' 2>/dev/null | tail -1)
check "an interactive zsh reads .zshrc" test "$out" = "RC=true"

out=$(env -i HOME="$HOME" TERM=xterm PATH=/usr/bin:/bin \
  zsh -c 'echo "${ZDOTDIR:-unset}"' 2>/dev/null | tail -1)
check "ZDOTDIR stays unset" test "$out" = "unset"

echo
if [ "$FAILED" -gt 0 ]; then
  echo "RESULT: $FAILED check(s) failed"
  exit 1
fi
echo "RESULT: every check passed"
SCRIPT
