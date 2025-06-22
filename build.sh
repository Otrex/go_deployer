#!/bin/bash
set -e

APP_NAME="deployer"
SRC_DIR="./src"
BUILD_DIR="./build"

echo "🔨 Building $APP_NAME for Linux, macOS (Intel), and macOS (Apple Silicon)..."

mkdir -p "$BUILD_DIR/linux"
mkdir -p "$BUILD_DIR/mac-amd64"
mkdir -p "$BUILD_DIR/mac-arm64"

# Linux build
GOOS=linux GOARCH=amd64 go build -o "$BUILD_DIR/linux/$APP_NAME" "$SRC_DIR"
echo "✅ Linux build complete"

# macOS Intel build
GOOS=darwin GOARCH=amd64 go build -o "$BUILD_DIR/mac-amd64/$APP_NAME" "$SRC_DIR"
echo "✅ macOS Intel build complete"

# macOS ARM64 (M1/M2/M3)
GOOS=darwin GOARCH=arm64 go build -o "$BUILD_DIR/mac-arm64/$APP_NAME" "$SRC_DIR"
echo "✅ macOS ARM64 build complete"
