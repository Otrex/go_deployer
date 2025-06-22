#!/bin/bash
set -e

APP_NAME="deployer"
INSTALL_PATH="/usr/local/bin/$APP_NAME"
SUPERVISOR_CONF_DIR="/etc/supervisor/conf.d"
SUPERVISOR_FLAG="/usr/local/bin/.installed_by_deployer"
SUPERVISOR_LOG_DIR="/var/log/$APP_NAME"
LAUNCHD_PLIST="$HOME/Library/LaunchAgents/com.example.$APP_NAME.plist"
ENV_FILE=""

# Parse --env flag
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

OS=$(uname -s)
ARCH=$(uname -m)

if [[ "$OS" == "Linux" ]]; then
  echo "📦 Detected Linux [$ARCH]"

  if ! command -v supervisord >/dev/null 2>&1; then
    echo "🛠 Installing supervisor..."
    sudo apt update
    sudo apt install -y supervisor
    echo "✅ Supervisor installed."
    echo "installed" | sudo tee "$SUPERVISOR_FLAG" >/dev/null
  else
    echo "✅ Supervisor already installed."
  fi

  # Create log directory
  sudo mkdir -p "$SUPERVISOR_LOG_DIR"
  sudo touch "$SUPERVISOR_LOG_DIR/$APP_NAME.out.log" "$SUPERVISOR_LOG_DIR/$APP_NAME.err.log"
  sudo chmod 666 "$SUPERVISOR_LOG_DIR"/*.log

  # Create supervisor config
  sudo tee "$SUPERVISOR_CONF_DIR/$APP_NAME.conf" > /dev/null <<EOF
[program:$APP_NAME]
command=$INSTALL_PATH --envFile=$ENV_FILE
autostart=true
autorestart=true
stderr_logfile=$SUPERVISOR_LOG_DIR/$APP_NAME.err.log
stdout_logfile=$SUPERVISOR_LOG_DIR/$APP_NAME.out.log
EOF

  # Reload supervisor
  sudo supervisorctl reread
  sudo supervisorctl update
  sudo supervisorctl restart "$APP_NAME"

  echo "🚀 $APP_NAME is now running under supervisord."

elif [[ "$OS" == "Darwin" ]]; then
  echo "🍎 Detected macOS [$ARCH]"

  mkdir -p "$(dirname "$LAUNCHD_PLIST")"
  tee "$LAUNCHD_PLIST" > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.example.$APP_NAME</string>

  <key>ProgramArguments</key>
  <array>
    <string>$INSTALL_PATH</string>
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

  launchctl unload "$LAUNCHD_PLIST" 2>/dev/null || true
  launchctl load "$LAUNCHD_PLIST"
  echo "🚀 $APP_NAME is now running under launchd"

else
  echo "❌ Unsupported platform: $OS"
  exit 1
fi

echo "✅ Installation complete"
