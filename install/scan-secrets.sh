#!/bin/sh
# Scan for a leaked credential before it reaches a commit.
#
# Usage:
#   install/scan-secrets.sh            scan the whole working tree
#   install/scan-secrets.sh --staged   scan only what is staged
#   install/scan-secrets.sh PATH...    scan an explicit list
#
# Wire it into git:
#   ln -s ../../install/scan-secrets.sh .git/hooks/pre-commit
#
# git runs a hook with GIT_DIR and GIT_INDEX_FILE already set, and from the
# repository root. The script clears GIT_DIR so `git ls-files` works, and it
# scans the staged content, because a commit records the index and not the
# working tree.
#
# This repo is PUBLIC. An internal hostname is a leak too, not only a token.

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd -P)

# git runs a hook from the repository root and exports GIT_INDEX_FILE as a
# RELATIVE path. Make it absolute before any `cd`, or every later git call
# reads the wrong index and the scan reports a clean tree.
if [ -n "${GIT_INDEX_FILE:-}" ]; then
  case "$GIT_INDEX_FILE" in
    /*) ;;
    *) GIT_INDEX_FILE="$PWD/$GIT_INDEX_FILE" ;;
  esac
  export GIT_INDEX_FILE
fi

cd "$REPO_ROOT"

# A hook inherits these. They make every later git call resolve wrongly.
unset GIT_DIR GIT_WORK_TREE 2>/dev/null || true

MODE=tree
case "${1:-}" in
  --staged)
    MODE=staged
    shift
    ;;
esac

# A pre-commit hook must judge the index, not the working tree. git sets
# GIT_INDEX_FILE for every hook, so that is the reliable signal.
if [ $# -eq 0 ] && [ -n "${GIT_INDEX_FILE:-}" ]; then
  MODE=staged
fi

WORK="${TMPDIR:-/tmp}/dotfiles-scan.$$"
LIST="$WORK.files"
REPORT="$WORK.report"
BLOB="$WORK.blob"
: >"$REPORT"
trap 'rm -f "$LIST" "$REPORT" "$BLOB"' EXIT INT TERM

# ------------------------------------------------------------- file list ----

if [ $# -gt 0 ]; then
  printf '%s\n' "$@" >"$LIST"
elif [ "$MODE" = staged ]; then
  # Added, copied, modified, or renamed. A deletion cannot leak.
  git diff --cached --name-only --diff-filter=ACMR >"$LIST"
else
  {
    git ls-files
    git ls-files --others --exclude-standard
  } | sort -u >"$LIST"
fi

grep -vE '^install/test/ca/|\.(png|jpg|jpeg|gif|zip|gz|xz|zst|pdf|ico|woff2?)$' \
  "$LIST" >"$LIST.tmp" 2>/dev/null || : >"$LIST.tmp"
mv "$LIST.tmp" "$LIST"

# Read a file's content from the index in staged mode, from disk otherwise.
content_of() {
  if [ "$MODE" = staged ]; then
    git show ":$1" 2>/dev/null || return 1
  else
    [ -f "$1" ] || return 1
    cat -- "$1"
  fi
}

record() {
  printf '%s|%s\n' "$1" "$2" >>"$REPORT"
}

# ---------------------------------------------------------------- content ----
#
# One pass over each file, every pattern applied to the same content. This
# keeps the staged read to a single git call per file.

while read -r f; do
  [ -n "$f" ] || continue
  content_of "$f" >"$BLOB" 2>/dev/null || continue

  # description | regex, one per line.
  while IFS='|' read -r desc re; do
    [ -n "$desc" ] || continue
    hits=$(grep -nE "$re" "$BLOB" 2>/dev/null | head -3) || continue
    [ -n "$hits" ] || continue
    printf '%s\n' "$hits" | while IFS= read -r hit; do
      record "$desc" "$f:$hit"
    done
  done <<'PATTERNS'
GitHub token|gh[pousr]_[A-Za-z0-9]{16,}
GitLab token|glpat-[A-Za-z0-9_-]{16,}
OpenAI key|sk-[A-Za-z0-9]{32,}
Anthropic key|sk-ant-[A-Za-z0-9_-]{20,}
AWS access key|AKIA[A-Z0-9]{16}
pi provider token|bgpat-[A-Za-z0-9_-]{16,}
Slack token|xox[abprs]-[A-Za-z0-9-]{10,}
private key block|BEGIN (RSA|OPENSSH|DSA|EC|PGP) PRIVATE KEY
literal credential value|"(api_?key|apiKey|token|secret|password)"[[:space:]]*:[[:space:]]*"[^"$!][^"]{12,}"
internal hostname|[A-Za-z0-9-]+\.(internal|corp|intranet)\b
employer hostname|[A-Za-z0-9.-]*blueorigin\.com
PATTERNS
done <"$LIST"

# ------------------------------------------------------------ pi runtime ----
#
# Each of these pi files holds a credential, a host endpoint, or machine
# state. None belongs in the repo, whatever its content looks like.

present() {
  if [ "$MODE" = staged ]; then
    grep -Fxq -- "$1" "$LIST"
  else
    [ -e "$1" ]
  fi
}

for bad in auth.json models.json trust.json models-store.json \
  mcp-cache.json mcp-onboarding.json settings.json; do
  if present "pi/.pi/agent/$bad"; then
    record "pi runtime file in the repo" "pi/.pi/agent/$bad"
  fi
done

for bad in sessions mcp-oauth mcp-auth npm git bin plans .worktrees; do
  if [ "$MODE" = staged ]; then
    if grep -q "^pi/\.pi/agent/$bad/" "$LIST" 2>/dev/null; then
      record "pi runtime path in the repo" "pi/.pi/agent/$bad/"
    fi
  elif [ -e "pi/.pi/agent/$bad" ]; then
    record "pi runtime path in the repo" "pi/.pi/agent/$bad"
  fi
done

# ----------------------------------------------------------------- report ----

if [ -s "$REPORT" ]; then
  count=$(wc -l <"$REPORT" | tr -d ' ')
  printf 'Secret scan (%s): %s finding(s).\n\n' "$MODE" "$count" >&2
  while IFS='|' read -r desc where; do
    printf 'LEAK  %s\n      %s\n' "$desc" "$where" >&2
  done <"$REPORT"
  printf '\nRemove every finding above. To commit anyway: git commit --no-verify\n' >&2
  exit 1
fi

printf 'Secret scan (%s): clean.\n' "$MODE"
