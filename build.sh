#!/bin/bash
set -e

APP_NAME="deployer"
SRC_DIR="./src"
BUILD_DIR="./build"

echo "🔨 Building $APP_NAME for multiple platforms..."

mkdir -p "$BUILD_DIR/linux-amd64"
mkdir -p "$BUILD_DIR/linux-arm64"
mkdir -p "$BUILD_DIR/mac-amd64"
mkdir -p "$BUILD_DIR/mac-arm64"

# Linux AMD64
GOOS=linux GOARCH=amd64 go build -o "$BUILD_DIR/linux-amd64/$APP_NAME" "$SRC_DIR"
echo "✅ Built for Linux amd64"

# Linux ARM64
GOOS=linux GOARCH=arm64 go build -o "$BUILD_DIR/linux-arm64/$APP_NAME" "$SRC_DIR"
echo "✅ Built for Linux arm64"

# macOS AMD64
GOOS=darwin GOARCH=amd64 go build -o "$BUILD_DIR/mac-amd64/$APP_NAME" "$SRC_DIR"
echo "✅ Built for macOS amd64"

# macOS ARM64
GOOS=darwin GOARCH=arm64 go build -o "$BUILD_DIR/mac-arm64/$APP_NAME" "$SRC_DIR"
echo "✅ Built for macOS arm64"
