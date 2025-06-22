#!/bin/bash

set -e

APP_NAME="deployer"
SRC_DIR="./src"
BUILD_DIR="./build"

# Target folders
LINUX_DIR="$BUILD_DIR/linux"
MAC_AMD_DIR="$BUILD_DIR/mac"
MAC_ARM_DIR="$BUILD_DIR/mac-arm64"

# Create output directories
mkdir -p "$LINUX_DIR" "$MAC_AMD_DIR" "$MAC_ARM_DIR"

echo "🔧 Building for Linux (amd64)..."
GOOS=linux GOARCH=amd64 go build -o "$LINUX_DIR/$APP_NAME" "$SRC_DIR"

echo "🍏 Building for macOS (Intel)..."
GOOS=darwin GOARCH=amd64 go build -o "$MAC_AMD_DIR/$APP_NAME" "$SRC_DIR"

echo "🍎 Building for macOS (Apple Silicon)..."
GOOS=darwin GOARCH=arm64 go build -o "$MAC_ARM_DIR/$APP_NAME" "$SRC_DIR"

# -------------------------------
# Create systemd service for Linux
# -------------------------------
LINUX_SERVICE_FILE="$LINUX_DIR/${APP_NAME}.service"

cat > "$LINUX_SERVICE_FILE" <<EOF
[Unit]
Description=$APP_NAME Service (Linux)
After=network.target

[Service]
ExecStart=$(pwd)/$LINUX_DIR/$APP_NAME
WorkingDirectory=$(pwd)
Restart=always
StandardOutput=append:$LINUX_DIR/${APP_NAME}.log
StandardError=append:$LINUX_DIR/${APP_NAME}.err

[Install]
WantedBy=multi-user.target
EOF

echo "📝 Linux systemd service created: $LINUX_SERVICE_FILE"

# -------------------------------
# Create launchd plist for macOS (Intel and ARM)
# -------------------------------
function create_plist() {
  local target_dir=$1
  local label=$2
  local plist_file="$target_dir/${label}.plist"

  cat > "$plist_file" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>

  <key>ProgramArguments</key>
  <array>
    <string>$(pwd)/$target_dir/$APP_NAME</string>
  </array>

  <key>WorkingDirectory</key>
  <string>$(pwd)</string>

  <key>StandardOutPath</key>
  <string>$(pwd)/$target_dir/${APP_NAME}.log</string>

  <key>StandardErrorPath</key>
  <string>$(pwd)/$target_dir/${APP_NAME}.err</string>

  <key>RunAtLoad</key>
  <true/>

  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
EOF

  echo "📝 macOS launchd plist created: $plist_file"
}

create_plist "$MAC_AMD_DIR" "com.example.${APP_NAME}-amd64"
create_plist "$MAC_ARM_DIR" "com.example.${APP_NAME}-arm64"

echo "✅ All builds complete. Output located in: $BUILD_DIR"
