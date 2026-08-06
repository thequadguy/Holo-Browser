#!/usr/bin/env bash

# Holo Browser Professional Code Signing Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOLO_DIR="$ROOT_DIR/HoloBrowser"

APP_PATH="${1:-$ROOT_DIR/Build/Products/Release/Holo Browser.app}"
IDENTITY="${DEVELOPER_ID:--}"
ENTITLEMENTS_PATH="${ENTITLEMENTS:-$HOLO_DIR/Sources/App/HoloBrowser.entitlements}"

echo "=== 🔒 Code Signing Holo Browser Bundle ==="
echo "App Path:     $APP_PATH"
echo "Identity:     $IDENTITY"
echo "Entitlements: $ENTITLEMENTS_PATH"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: App bundle not found at $APP_PATH"
    exit 1
fi

SIGN_OPTS=(--force --options runtime)
if [ "$IDENTITY" != "-" ]; then
    SIGN_OPTS+=(--timestamp)
else
    SIGN_OPTS+=(--timestamp=none)
fi

if [ -f "$ENTITLEMENTS_PATH" ]; then
    SIGN_OPTS+=(--entitlements "$ENTITLEMENTS_PATH")
    echo "✓ Entitlements file detected."
else
    echo "⚠️ Warning: Entitlements file not found at $ENTITLEMENTS_PATH."
fi

# 1. Sign internal binary executable
echo "Signing inner executable..."
codesign "${SIGN_OPTS[@]}" --sign "$IDENTITY" "$APP_PATH/Contents/MacOS/HoloBrowser"

# 2. Sign outer app bundle
echo "Signing outer bundle..."
codesign "${SIGN_OPTS[@]}" --sign "$IDENTITY" "$APP_PATH"

echo "✓ Code signing completed cleanly."
