#!/bin/bash
set -e

APP_NAME="deployer"
INSTALL_BIN="/usr/local/bin/$APP_NAME"
SUPERVISOR_FLAG="$HOME/.${APP_NAME}_installed_supervisor"
SUPERVISOR_CONF_DIR_LINUX="/etc/supervisor/conf.d"
SUPERVISOR_CONF_DIR_MAC="/usr/local/etc/supervisor.d"
SUPERVISOR_CONF_LINUX="$SUPERVISOR_CONF_DIR_LINUX/$APP_NAME.conf"
SUPERVISOR_CONF_MAC="$SUPERVISOR_CONF_DIR_MAC/$APP_NAME.conf"
LOG_DIR_LINUX="/var/log"
LOG_DIR_MAC="$HOME/Library/Logs"

# --- Detect platform ---
OS=$(uname -s)
ARCH=$(uname -m)

if [[ "$OS" == "Linux" ]]; then
  SUPERVISOR_CONF="$SUPERVISOR_CONF_LINUX"
  LOG_DIR="$LOG_DIR_LINUX"
elif [[ "$OS" == "Darwin" ]]; then
  SUPERVISOR_CONF="$SUPERVISOR_CONF_MAC"
  LOG_DIR="$LOG_DIR_MAC"
else
  echo "❌ Unsupported OS: $OS"
  exit 1
fi

# --- Stop and remove from supervisor ---
echo "🛑 Stopping $APP_NAME from supervisor..."

if command -v supervisorctl >/dev/null 2>&1; then
  if sudo supervisorctl status | grep -q "$APP_NAME"; then
    sudo supervisorctl stop "$APP_NAME" || true
    echo "✅ Stopped $APP_NAME"
  else
    echo "ℹ️ $APP_NAME not currently running under supervisor"
  fi

  if [[ -f "$SUPERVISOR_CONF" ]]; then
    sudo rm "$SUPERVISOR_CONF"
    echo "🗑️ Removed supervisor config: $SUPERVISOR_CONF"
    sudo supervisorctl reread
    sudo supervisorctl update
  else
    echo "ℹ️ No supervisor config found for $APP_NAME"
  fi
else
  echo "⚠️ supervisorctl not found; skipping supervisor stop"
fi

# --- Remove binary ---
if [[ -f "$INSTALL_BIN" ]]; then
  sudo rm "$INSTALL_BIN"
  echo "🗑️ Removed binary: $INSTALL_BIN"
else
  echo "ℹ️ Binary not found: $INSTALL_BIN"
fi

# --- Remove logs ---
LOG_FILES=("$LOG_DIR/$APP_NAME.out.log" "$LOG_DIR/$APP_NAME.err.log")
for log_file in "${LOG_FILES[@]}"; do
  if [[ -f "$log_file" ]]; then
    rm "$log_file"
    echo "🧹 Removed log: $log_file"
  fi
done

# --- Optionally uninstall supervisor ---
if [[ -f "$SUPERVISOR_FLAG" ]]; then
  echo "🧯 Supervisor was installed by this script. Uninstalling..."

  if [[ "$OS" == "Linux" ]]; then
    sudo apt remove -y supervisor
  elif [[ "$OS" == "Darwin" ]]; then
    brew uninstall supervisor || true
  fi

  rm "$SUPERVISOR_FLAG"
  echo "✅ Supervisor uninstalled"
else
  echo "ℹ️ Supervisor was not installed by this script — skipping uninstall"
fi

echo "✅ Uninstallation complete!"
