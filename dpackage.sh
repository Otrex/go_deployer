#!/bin/bash
set -e

# --- Configuration ---
INSTALL_URL="https://raw.githubusercontent.com/otrex/go_deployer/main/install.sh"
UNINSTALL_URL="https://raw.githubusercontent.com/otrex/go_deployer/main/uninstall.sh"
INSTALL_SCRIPT="install.sh"
UNINSTALL_SCRIPT="uninstall.sh"

# --- Ensure file exists and is executable ---
ensure_script() {
  local script_name=$1
  local script_url=$2

  if [[ ! -f "$script_name" ]]; then
    echo "⬇️  Downloading $script_name from $script_url"
    curl -fsSL "$script_url" -o "$script_name"
  else
    echo "✅ $script_name already exists"
  fi

  if [[ ! -x "$script_name" ]]; then
    echo "🔧 Making $script_name executable"
    chmod +x "$script_name"
  fi
}

# --- Handle commands ---
case "$1" in
  install)
    ensure_script "$INSTALL_SCRIPT" "$INSTALL_URL"
    echo "🚀 Running install..."
    ./"$INSTALL_SCRIPT" "${@:2}"  # forward remaining args
    ;;
  uninstall)
    ensure_script "$UNINSTALL_SCRIPT" "$UNINSTALL_URL"
    echo "🧹 Running uninstall..."
    ./"$UNINSTALL_SCRIPT" "${@:2}"
    ;;
  delete)
    echo "🗑️ Deleting $INSTALL_SCRIPT and $UNINSTALL_SCRIPT"
    rm -f "$INSTALL_SCRIPT" "$UNINSTALL_SCRIPT"
    echo "✅ Deleted."
    ;;
  *)
    echo "❌ Unknown command: $1"
    echo "Usage:"
    echo "  ./dpackage.sh install [args...]   - run install"
    echo "  ./dpackage.sh uninstall           - run uninstall"
    echo "  ./dpackage.sh delete              - remove install/uninstall scripts"
    exit 1
    ;;
esac
