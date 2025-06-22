#!/bin/bash
set -e

APP_NAME="deployer"
INSTALL_BIN="/usr/local/bin/$APP_NAME"
GITHUB_REPO="https://raw.githubusercontent.com/Otrex/go_deployer/main"
TMP_DIR="$(mktemp -d)"
SUPERVISOR_FLAG="$HOME/.${APP_NAME}_installed_supervisor"

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
elif [[ "$OS" == "Linux" && "$ARCH" == "aarch64" ]]; then
    PLATFORM="linux-arm64"
    BINARY_URL="$GITHUB_REPO/build/linux-arm64/$APP_NAME"
elif [[ "$OS" == "Darwin" && "$ARCH" == "x86_64" ]]; then
    PLATFORM="mac-amd64"
    BINARY_URL="$GITHUB_REPO/build/mac-amd64/$APP_NAME"
elif [[ "$OS" == "Darwin" && "$ARCH" == "arm64" ]]; then
    PLATFORM="mac-arm64"
    BINARY_URL="$GITHUB_REPO/build/mac-arm64/$APP_NAME"
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

# --- Install supervisord if needed ---
function install_supervisor_linux() {
  if ! command -v supervisord >/dev/null 2>&1; then
    echo "🔧 Installing supervisord (Linux)..."
    sudo apt update && sudo apt install -y supervisor
    echo "installed_by_script=true" > "$SUPERVISOR_FLAG"
  else
    echo "✅ supervisord already installed"
  fi
}

function install_supervisor_mac() {
  if ! command -v supervisord >/dev/null 2>&1; then
    echo "🔧 Installing supervisord (macOS)..."
    brew install supervisor
    mkdir -p ~/Library/LaunchAgents
    echo "installed_by_script=true" > "$SUPERVISOR_FLAG"
  else
    echo "✅ supervisord already installed"
  fi
}

if [[ "$OS" == "Linux" ]]; then
  install_supervisor_linux
elif [[ "$OS" == "Darwin" ]]; then
  install_supervisor_mac
fi

# --- Supervisor config setup ---
SUPERVISOR_CONF_DIR="/etc/supervisor/conf.d"
[ "$OS" = "Darwin" ] && SUPERVISOR_CONF_DIR="/usr/local/etc/supervisor.d"

SUPERVISOR_CONF="$SUPERVISOR_CONF_DIR/$APP_NAME.conf"

echo "🛠️ Writing supervisor config to $SUPERVISOR_CONF"

sudo tee "$SUPERVISOR_CONF" > /dev/null <<EOF
[program:$APP_NAME]
command=$INSTALL_BIN --envFile=$ENV_FILE
autostart=true
autorestart=true
stderr_logfile=/var/log/$APP_NAME.err.log
stdout_logfile=/var/log/$APP_NAME.out.log
EOF

# --- Start supervisor process ---
echo "🔄 Reloading supervisord"

if [[ "$OS" == "Linux" ]]; then
  sudo supervisorctl reread
  sudo supervisorctl update
  sudo supervisorctl restart "$APP_NAME"
elif [[ "$OS" == "Darwin" ]]; then
  supervisord -c /usr/local/etc/supervisord.ini
  supervisorctl reread
  supervisorctl update
  supervisorctl restart "$APP_NAME"
fi

echo "🚀 $APP_NAME is now running under supervisord"
rm -rf "$TMP_DIR"
