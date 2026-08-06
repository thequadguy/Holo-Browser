#!/usr/bin/env bash

# Holo Browser Verification & Audit Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_PATH="${1:-$ROOT_DIR/Build/Products/Release/Holo Browser.app}"

echo "=========================================================="
echo "🔎 Release Verification & Gatekeeper Assessment"
echo "=========================================================="

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: App bundle not found at $APP_PATH"
    exit 1
fi

EXECUTABLE="$APP_PATH/Contents/MacOS/HoloBrowser"

echo "1. Executable Architecture Audit:"
file "$EXECUTABLE"
otool -l "$EXECUTABLE" | grep -A3 "LC_BUILD_VERSION" | head -10 || true

echo ""
echo "2. Codesign Verification:"
codesign --verify --verbose --deep "$APP_PATH" || true
codesign -dvvv "$APP_PATH" 2>&1 | grep -E "Authority|Signature|Format|Identifier|Sealed Resources" || true

echo ""
echo "3. Entitlements Inspection:"
codesign -d --entitlements :- "$APP_PATH" 2>&1 || true

echo ""
echo "4. Info.plist Protocol Schemes (Default Browser Verification):"
plutil -extract CFBundleURLTypes xml1 -o - "$APP_PATH/Contents/Info.plist" 2>/dev/null || grep -A10 "CFBundleURLTypes" "$APP_PATH/Contents/Info.plist" || true

echo ""
echo "5. Gatekeeper Assessment:"
spctl --assess --type execute --verbose "$APP_PATH" 2>&1 || echo "(Ad-hoc development signature — standard behavior without Developer ID certificate)"

echo "=========================================================="
echo "✓ Verification assessment complete."
echo "=========================================================="
