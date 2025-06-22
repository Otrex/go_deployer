#!/bin/bash
set -e

APP_NAME="deployer"
INSTALL_BIN="/usr/local/bin/$APP_NAME"
GITHUB_REPO="https://raw.githubusercontent.com/Otrex/go_deployer/main"
TMP_DIR="$(mktemp -d)"

# --- Parse flags ---
ENV_FILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      ENV_FILE="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$ENV_FILE" ]]; then
  echo "❌ Missing --env /path/to/.env"
  exit 1
fi

# --- Detect platform ---
OS=$(uname -s)
ARCH=$(uname -m)

if [[ "$OS" == "Linux" && "$ARCH" == "x86_64" ]]; then
    PLATFORM="linux-amd64"
    BINARY_URL="$GITHUB_REPO/build/linux-amd64/$APP_NAME"
    SERVICE_FILE="/etc/systemd/system/$APP_NAME.service"
    LOG_DIR="/var/log/$APP_NAME"
elif [[ "$OS" == "Linux" && "$ARCH" == "aarch64" ]]; then
    PLATFORM="linux-arm64"
    BINARY_URL="$GITHUB_REPO/build/linux-arm64/$APP_NAME"
    SERVICE_FILE="/etc/systemd/system/$APP_NAME.service"
    LOG_DIR="/var/log/$APP_NAME"
elif [[ "$OS" == "Darwin" && "$ARCH" == "x86_64" ]]; then
    PLATFORM="mac-amd64"
    BINARY_URL="$GITHUB_REPO/build/mac-amd64/$APP_NAME"
    PLIST_NAME="com.example.$APP_NAME.plist"
    PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME"
elif [[ "$OS" == "Darwin" && "$ARCH" == "arm64" ]]; then
    PLATFORM="mac-arm64"
    BINARY_URL="$GITHUB_REPO/build/mac-arm64/$APP_NAME"
    PLIST_NAME="com.example.$APP_NAME.plist"
    PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME"
else
    echo "❌ Unsupported platform: $OS $ARCH"
    exit 1
fi

echo "📦 Platform: $PLATFORM"
echo "⬇️  Downloading $BINARY_URL"

# --- Download binary ---
curl -fsSL "$BINARY_URL" -o "$TMP_DIR/$APP_NAME"
chmod +x "$TMP_DIR/$APP_NAME"

# --- Install binary ---
sudo cp "$TMP_DIR/$APP_NAME" "$INSTALL_BIN"
sudo chmod +x "$INSTALL_BIN"
echo "✅ Installed to $INSTALL_BIN"

# --- Linux: systemd setup ---
if [[ "$OS" == "Linux" ]]; then
    sudo mkdir -p "$LOG_DIR"
    sudo touch "$LOG_DIR/$APP_NAME.log" "$LOG_DIR/$APP_NAME.err"
    sudo chmod 666 "$LOG_DIR"/*.log

    sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=$APP_NAME Service
After=network.target

[Service]
ExecStart=$INSTALL_BIN --envFile=$ENV_FILE
Restart=always
StandardOutput=append:$LOG_DIR/$APP_NAME.log
StandardError=append:$LOG_DIR/$APP_NAME.err

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable "$APP_NAME"
    sudo systemctl restart "$APP_NAME"
    echo "🚀 $APP_NAME is running on Linux via systemd"

# --- macOS: launchd setup ---
else
    mkdir -p "$(dirname "$PLIST_PATH")"
    tee "$PLIST_PATH" > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.example.$APP_NAME</string>

  <key>ProgramArguments</key>
  <array>
    <string>$INSTALL_BIN</string>
    <string>--envFile=$ENV_FILE</string>
  </array>

  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>

  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/${APP_NAME}.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/${APP_NAME}.err</string>
</dict>
</plist>
EOF

    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    launchctl load "$PLIST_PATH"
    echo "🚀 $APP_NAME is running on macOS via launchd"
fi

# --- Cleanup ---
rm -rf "$TMP_DIR"
echo "✅ Installation complete!"
