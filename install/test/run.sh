#!/bin/sh
# Run the bootstrap inside a container and check the result.
#
# Usage:
#   install/test/run.sh [link|full|nfs|all|shell] [--keep]
#
#   link   link only. Needs no network beyond the antidote clone. Fast.
#   full   link plus the whole tool install. Slow. Needs network egress.
#   nfs    a network home: the cache redirect and the zsh startup order.
#   shell  drop into a shell in a fresh container. For a manual check.
#
# --keep leaves a shell open after the checks finish.
#
# Set DOTFILES_TEST_BASE to change the base image.

set -eu

MODE=${1:-link}
KEEP=${2:-}
REPO=$(cd "$(dirname "$0")/../.." && pwd -P)
IMAGE=dotfiles-test
BASE=${DOTFILES_TEST_BASE:-registry.access.redhat.com/ubi9/ubi:latest}

cd "$REPO"

# A corporate proxy that intercepts TLS breaks curl inside the container.
# Copy the CAs the host trusts so the image trusts them too.
CA_DIR=install/test/ca
mkdir -p "$CA_DIR"
rm -f "$CA_DIR"/*.crt
: >"$CA_DIR/.gitkeep"
for store in /usr/local/share/ca-certificates /etc/pki/ca-trust/source/anchors; do
  [ -d "$store" ] || continue
  for c in "$store"/*.crt "$store"/*.pem; do
    [ -f "$c" ] || continue
    cp "$c" "$CA_DIR/$(basename "${c%.*}").crt"
  done
done
CA_COUNT=$(find "$CA_DIR" -name '*.crt' | wc -l | tr -d ' ')
echo "==> Host CAs copied into the image: $CA_COUNT"

echo "==> Building $IMAGE from $BASE"
docker build --quiet --build-arg "BASE=$BASE" \
  -f install/test/Dockerfile -t "$IMAGE" . >/dev/null

# mise reads release lists from the GitHub API. An unauthenticated caller
# gets 60 calls per hour, shared with every host behind the same address.
# Pass a token through when the host has one.
GH_ARGS=''
if [ -n "${GITHUB_TOKEN:-}" ]; then
  GH_ARGS="-e GITHUB_TOKEN=$GITHUB_TOKEN"
  echo "==> A GitHub token is present"
else
  echo "==> No GITHUB_TOKEN. The API limit may make a download fail."
fi

case $MODE in
  link) SCRIPT=/home/tester/dotfiles/install/test/case-link.sh ;;
  full) SCRIPT=/home/tester/dotfiles/install/test/case-full.sh ;;
  nfs) SCRIPT=/home/tester/dotfiles/install/test/case-nfs.sh ;;
  all)
    for m in link nfs full; do
      echo "==> Running the $m case"
      # shellcheck disable=SC2086
      docker run --rm $GH_ARGS "$IMAGE" sh "/home/tester/dotfiles/install/test/case-$m.sh" \
        || exit 1
    done
    exit 0
    ;;
  shell)
    # shellcheck disable=SC2086
    exec docker run --rm -it $GH_ARGS "$IMAGE" bash
    ;;
  *)
    echo "unknown mode: $MODE" >&2
    exit 2
    ;;
esac

echo "==> Running the $MODE case"
if [ "$KEEP" = --keep ]; then
  # shellcheck disable=SC2086
  docker run --rm -it $GH_ARGS "$IMAGE" sh -c "$SCRIPT; exec bash"
else
  # shellcheck disable=SC2086
  docker run --rm $GH_ARGS "$IMAGE" sh "$SCRIPT"
fi
