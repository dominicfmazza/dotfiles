# lock.sh: write mise/.config/mise/mise.lock for every profile file and
# every platform. Run it after a pin change, then commit the lock file.
#
# A host links the lock file into ~/.config/mise. `mise install --locked`
# then gets the exact URL and checksum of each tool. A host with a small
# profile reads only the entries for its own tools.
# shellcheck shell=sh
set -eu
: "${DOTFILES_REPO:?run this through mise: mise run lock}"
MISE=${DOTFILES_MISE:-mise}
src="$DOTFILES_REPO/mise/.config/mise"
platforms=${DOTFILES_LOCK_PLATFORMS:-linux-x64,linux-arm64,macos-x64,macos-arm64}

# mise locks the global config of the current home. A temp home with every
# profile file in conf.d gives one lock that covers each profile.
home=$(mktemp -d "${TMPDIR:-/tmp}/dotlock.XXXXXX")
trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/mise/conf.d"
ln -s "$src/config.toml" "$home/.config/mise/config.toml"
for f in "$src"/profiles/*.toml; do
  ln -s "$f" "$home/.config/mise/conf.d/"
done
[ -f "$src/mise.lock" ] || : >"$src/mise.lock"
ln -s "$src/mise.lock" "$home/.config/mise/mise.lock"

cd "$home"
HOME=$home XDG_CONFIG_HOME="$home/.config" \
  MISE_DATA_DIR="${MISE_DATA_DIR:-$HOME/.local/share/mise}" \
  MISE_CACHE_DIR="${MISE_CACHE_DIR:-$HOME/.cache/mise}" \
  MISE_STATE_DIR="$home/state" \
  "$MISE" lock --global --platform "$platforms"
echo "==> Wrote $src/mise.lock. Commit it."
