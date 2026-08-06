#!/usr/bin/env bash

# Holo Browser Desktop Installer Script for Local Private Beta
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="/Users/jake/Desktop/Holo Browser"

echo "=== 🛠 Step 1: Building Holo Browser Release App ==="
"$SCRIPT_DIR/build_app.sh"

APP_SOURCE="$ROOT_DIR/Build/Products/Release/Holo Browser.app"
DESKTOP_TARGET="/Users/jake/Desktop/Holo Browser RC2.app"
APPS_TARGET="/Users/jake/Applications/Holo Browser.app"

echo "=== 📲 Step 2: Installing to Desktop and Applications ==="
mkdir -p "/Users/jake/Applications"

rm -rf "$DESKTOP_TARGET"
rm -rf "$APPS_TARGET"

cp -R "$APP_SOURCE" "$DESKTOP_TARGET"
cp -R "$APP_SOURCE" "$APPS_TARGET"

echo ""
echo "=========================================================="
echo "🎉 HOLO BROWSER 1.0 RC2 INSTALLED SUCCESSFULLY!"
echo "=========================================================="
echo "📍 Desktop Location:     $DESKTOP_TARGET"
echo "📍 Applications Folder:  $APPS_TARGET"
echo ""
echo "To Launch:"
echo "1. Open Finder -> Desktop -> Double Click 'Holo Browser RC2.app'"
echo "2. Or open Spotlight (⌘Space) and type 'Holo Browser'"
echo "=========================================================="
