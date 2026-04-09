#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="$ROOT_DIR/.runtime/server.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "status=stopped"
  exit 0
fi

PID="$(cat "$PID_FILE")"
if kill -0 "$PID" 2>/dev/null; then
  echo "status=running pid=$PID"
  exit 0
fi

echo "status=stale_pid"
exit 0
