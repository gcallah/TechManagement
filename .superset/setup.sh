#!/usr/bin/env bash
# Superset workspace setup for TechManagement (static HTML site).
# There are no dependencies to install; this copies untracked local files
# (env files, working docs) from the main checkout into the new worktree.
set -euo pipefail

WS="${SUPERSET_WORKSPACE_PATH:-$(pwd)}"
ROOT="${SUPERSET_ROOT_PATH:-}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "warning: python3 not found; the Run command (dev server) needs it." >&2
fi

if [[ -z "$ROOT" || ! -d "$ROOT" ]]; then
  echo "SUPERSET_ROOT_PATH not set or missing; nothing to copy."
  exit 0
fi
if [[ "$(cd "$ROOT" && pwd -P)" == "$(cd "$WS" && pwd -P)" ]]; then
  echo "Workspace is the root checkout; nothing to copy."
  exit 0
fi

copy_one() {
  local rel="$1"
  local src="$ROOT/$rel" dst="$WS/$rel"
  [[ -f "$src" ]] || return 0
  if [[ -e "$dst" ]]; then
    echo "skip (exists): $rel"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  cp -p "$src" "$dst"
  echo "copied: $rel"
}

# 1. Untracked, non-ignored files in the root checkout (e.g. working .docx/.pdf).
while IFS= read -r -d '' f; do
  copy_one "$f"
done < <(git -C "$ROOT" ls-files -z --others --exclude-standard)

# 2. Env files, which are usually gitignored and so missed above.
while IFS= read -r -d '' f; do
  copy_one "${f#"$ROOT"/}"
done < <(find "$ROOT" -maxdepth 1 -type f -name '.env*' -print0)

echo "Setup complete."
