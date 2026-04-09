#!/usr/bin/env bash
set -euo pipefail

SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_ROOT="${NANO_BANANA_INSTALL_ROOT:-$HOME/nano-banana-pro-oss}"
ROOT_DIR="$INSTALL_ROOT"
LABEL="com.kunding.nano-banana-pro-oss"
PORT="${1:-8787}"
UID_VALUE="$(id -u)"
DOMAIN="gui/${UID_VALUE}"
SERVICE="${DOMAIN}/${LABEL}"
PLIST_PATH="$HOME/Library/LaunchAgents/${LABEL}.plist"
RUNTIME_DIR="${INSTALL_ROOT}/.runtime"
LOCAL_BIN_DIR="$HOME/.local/bin"
CLI_PATH="${LOCAL_BIN_DIR}/nano-banana-pro"

mkdir -p "$HOME/Library/LaunchAgents" "$RUNTIME_DIR" "$LOCAL_BIN_DIR" "$INSTALL_ROOT"

if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete \
    --exclude ".git" \
    --exclude ".runtime" \
    "${SOURCE_ROOT}/" "${INSTALL_ROOT}/"
else
  rm -rf "${INSTALL_ROOT}/app" "${INSTALL_ROOT}/prompts" "${INSTALL_ROOT}/scripts"
  cp -R "${SOURCE_ROOT}/app" "${INSTALL_ROOT}/app"
  cp -R "${SOURCE_ROOT}/prompts" "${INSTALL_ROOT}/prompts"
  cp -R "${SOURCE_ROOT}/scripts" "${INSTALL_ROOT}/scripts"
  cp "${SOURCE_ROOT}/README.md" "${INSTALL_ROOT}/README.md"
  cp "${SOURCE_ROOT}/LICENSE" "${INSTALL_ROOT}/LICENSE"
  cp "${SOURCE_ROOT}/.gitignore" "${INSTALL_ROOT}/.gitignore"
fi

cat >"$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>

  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/python3</string>
    <string>-m</string>
    <string>http.server</string>
    <string>${PORT}</string>
    <string>--bind</string>
    <string>127.0.0.1</string>
    <string>--directory</string>
    <string>${INSTALL_ROOT}</string>
  </array>

  <key>WorkingDirectory</key>
  <string>/</string>

  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>

  <key>StandardOutPath</key>
  <string>${INSTALL_ROOT}/.runtime/launchd.out.log</string>
  <key>StandardErrorPath</key>
  <string>${INSTALL_ROOT}/.runtime/launchd.err.log</string>
</dict>
</plist>
EOF

cat >"$CLI_PATH" <<EOF
#!/usr/bin/env bash
set -euo pipefail

LABEL="${LABEL}"
UID_VALUE="\$(id -u)"
DOMAIN="gui/\${UID_VALUE}"
SERVICE="\${DOMAIN}/\${LABEL}"
PLIST_PATH="\$HOME/Library/LaunchAgents/\${LABEL}.plist"
PORT="\${NANO_BANANA_PORT:-${PORT}}"
ACTION="\${1:-open}"

case "\$ACTION" in
  start)
    launchctl kickstart -k "\$SERVICE" >/dev/null 2>&1 || launchctl bootstrap "\$DOMAIN" "\$PLIST_PATH"
    echo "started service=\$LABEL url=http://127.0.0.1:\$PORT/app/"
    ;;
  stop)
    launchctl bootout "\$DOMAIN" "\$PLIST_PATH" >/dev/null 2>&1 || true
    echo "stopped service=\$LABEL"
    ;;
  status)
    if launchctl print "\$SERVICE" >/dev/null 2>&1; then
      echo "status=running service=\$LABEL"
    else
      echo "status=stopped service=\$LABEL"
    fi
    ;;
  open)
    launchctl kickstart -k "\$SERVICE" >/dev/null 2>&1 || launchctl bootstrap "\$DOMAIN" "\$PLIST_PATH"
    open "http://127.0.0.1:\$PORT/app/"
    ;;
  *)
    echo "usage: nano-banana-pro [start|stop|status|open]"
    exit 1
    ;;
esac
EOF

chmod +x "$CLI_PATH"

launchctl bootout "$DOMAIN" "$PLIST_PATH" >/dev/null 2>&1 || true
launchctl bootstrap "$DOMAIN" "$PLIST_PATH"
launchctl enable "$SERVICE" >/dev/null 2>&1 || true
launchctl kickstart -k "$SERVICE"

echo "installed service=${LABEL}"
echo "cli=${CLI_PATH}"
echo "root=${INSTALL_ROOT}"
echo "open=http://127.0.0.1:${PORT}/app/"
