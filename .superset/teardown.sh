#!/usr/bin/env bash
# Stop the dev server started by run.sh, if still running. Never fails.
cd "${SUPERSET_WORKSPACE_PATH:-$(dirname "$0")/..}" 2>/dev/null || exit 0
pidfile=.superset/run.pid
if [[ -f "$pidfile" ]]; then
  pid=$(cat "$pidfile" 2>/dev/null || true)
  if [[ -n "$pid" ]] && ps -p "$pid" -o command= 2>/dev/null | grep -q python; then
    kill "$pid" 2>/dev/null || true
    echo "Stopped dev server (pid $pid)."
  fi
  rm -f "$pidfile"
fi
exit 0
