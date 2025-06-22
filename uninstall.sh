#!/bin/bash
set -e

APP_NAME="deployer"
INSTALL_BIN="/usr/local/bin/$APP_NAME"

OS=$(uname -s)
ARCH=$(uname -m)

echo "🧼 Uninstalling $APP_NAME..."

if [[ "$OS" == "Linux" ]]; then
    SERVICE_FILE="/etc/systemd/system/$APP_NAME.service"
    LOG_DIR="/var/log/$APP_NAME"

    echo "🔧 Stopping and disabling systemd service..."
    sudo systemctl stop "$APP_NAME" || true
    sudo systemctl disable "$APP_NAME" || true
    sudo systemctl daemon-reload

    echo "🗑️  Removing service and logs..."
    sudo rm -f "$SERVICE_FILE"
    sudo rm -rf "$LOG_DIR"

elif [[ "$OS" == "Darwin" ]]; then
    PLIST_NAME="com.example.$APP_NAME.plist"
    PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME"
    LOG_DIR="$HOME/Library/Logs"

    echo "🔧 Unloading launch agent..."
    launchctl unload "$PLIST_PATH" 2>/dev/null || true

    echo "🗑️  Removing plist and logs..."
    rm -f "$PLIST_PATH"
    rm -f "$LOG_DIR/$APP_NAME.log" "$LOG_DIR/$APP_NAME.err"

else
    echo "❌ Unsupported OS: $OS"
    exit 1
fi

# Remove binary
if [[ -f "$INSTALL_BIN" ]]; then
    echo "🗑️  Removing binary from $INSTALL_BIN..."
    sudo rm -f "$INSTALL_BIN"
fi

echo "✅ $APP_NAME has been fully uninstalled."
