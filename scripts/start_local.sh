#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${1:-8787}"
RUNTIME_DIR="$ROOT_DIR/.runtime"
PID_FILE="$RUNTIME_DIR/server.pid"
LOG_FILE="$RUNTIME_DIR/server.log"

mkdir -p "$RUNTIME_DIR"

if [ -f "$PID_FILE" ]; then
  OLD_PID="$(cat "$PID_FILE")"
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo "already_running pid=$OLD_PID port=$PORT"
    exit 0
  fi
  rm -f "$PID_FILE"
fi

cd "$ROOT_DIR"
nohup python3 -m http.server "$PORT" >"$LOG_FILE" 2>&1 &
NEW_PID="$!"
sleep 0.6

if kill -0 "$NEW_PID" 2>/dev/null; then
  echo "$NEW_PID" > "$PID_FILE"
  echo "started pid=$NEW_PID port=$PORT url=http://127.0.0.1:$PORT/app/"
  exit 0
fi

echo "failed_to_start"
exit 1
