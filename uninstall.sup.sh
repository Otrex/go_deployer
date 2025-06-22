#!/bin/bash
set -e

APP_NAME="deployer"
SUPERVISOR_CONF="/etc/supervisor/conf.d/$APP_NAME.conf"
SUPERVISOR_FLAG="/usr/local/bin/.installed_by_deployer"
LAUNCHD_PLIST="$HOME/Library/LaunchAgents/com.example.$APP_NAME.plist"
LOG_DIR_LINUX="/var/log/$APP_NAME"
BIN_PATH="/usr/local/bin/$APP_NAME"

OS=$(uname -s)

if [[ "$OS" == "Linux" ]]; then
  echo "🧹 Uninstalling from Linux..."

  if command -v supervisorctl >/dev/null 2>&1; then
    sudo supervisorctl stop "$APP_NAME" || true
    sudo rm -f "$SUPERVISOR_CONF"
    sudo supervisorctl reread
    sudo supervisorctl update
  fi

  sudo rm -rf "$LOG_DIR_LINUX"
  sudo rm -f "$BIN_PATH"

  if [[ -f "$SUPERVISOR_FLAG" ]]; then
    echo "🔻 Removing supervisor (installed by deployer)..."
    sudo apt remove -y supervisor
    sudo rm -f "$SUPERVISOR_FLAG"
  else
    echo "ℹ️ Supervisor was not installed by this script."
  fi

elif [[ "$OS" == "Darwin" ]]; then
  echo "🧹 Uninstalling from macOS..."

  launchctl unload "$LAUNCHD_PLIST" 2>/dev/null || true
  rm -f "$LAUNCHD_PLIST"
  rm -f "$BIN_PATH"
  rm -f "$HOME/Library/Logs/${APP_NAME}.log"
  rm -f "$HOME/Library/Logs/${APP_NAME}.err"

else
  echo "❌ Unsupported OS for uninstall: $OS"
  exit 1
fi

echo "✅ Uninstallation complete"
