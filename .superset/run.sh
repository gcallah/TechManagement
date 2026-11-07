#!/usr/bin/env bash
# Serve the static site. Picks a free port per workspace so parallel
# workspaces don't collide: starts at a stable offset derived from the
# workspace name (or $PORT if set) and probes upward.
set -euo pipefail

cd "${SUPERSET_WORKSPACE_PATH:-$(dirname "$0")/..}"

if [[ -z "${PORT:-}" ]]; then
  name="${SUPERSET_WORKSPACE_NAME:-$(basename "$(pwd)")}"
  hash=$(printf '%s' "$name" | cksum | awk '{print $1}')
  PORT=$((8000 + hash % 1000))
fi
export PORT

# Record our PID so teardown can stop the server; exec keeps the same PID.
echo $$ > .superset/run.pid

exec python3 - <<'PY'
import os, sys
from functools import partial
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler

start = int(os.environ["PORT"])
handler = partial(SimpleHTTPRequestHandler, directory=os.getcwd())
for port in range(start, start + 200):
    try:
        httpd = ThreadingHTTPServer(("127.0.0.1", port), handler)
        break
    except OSError:
        continue
else:
    sys.exit(f"No free port found in {start}-{start + 199}")

print(f"Serving TechManagement at http://localhost:{port}/", flush=True)
try:
    httpd.serve_forever()
except KeyboardInterrupt:
    pass
PY
