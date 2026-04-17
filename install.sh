#!/bin/bash
set -euo pipefail

APP_NAME="GhosttySSH"
BUNDLE_ID="com.dbern.ghosttyssh"
INSTALL_DIR="$HOME/Applications"
APP_PATH="$INSTALL_DIR/$APP_NAME.app"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Building $APP_NAME..."
mkdir -p "$APP_PATH/Contents/MacOS"

swiftc -o "$APP_PATH/Contents/MacOS/$APP_NAME" "$SCRIPT_DIR/SSHHandler.swift" -framework Cocoa
cp "$SCRIPT_DIR/Info.plist" "$APP_PATH/Contents/Info.plist"

echo "Registering with Launch Services..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -R "$APP_PATH"

if command -v duti &>/dev/null; then
    duti -s "$BUNDLE_ID" ssh
    echo "Set $APP_NAME as default ssh:// handler via duti."
else
    echo "duti not found. Install with: brew install duti"
    echo "Then run: duti -s $BUNDLE_ID ssh"
fi

echo ""
echo "Installed to $APP_PATH"
echo "Test with: open ssh://user@host"
