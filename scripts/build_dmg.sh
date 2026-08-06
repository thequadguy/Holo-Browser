#!/usr/bin/env bash
# Holo Browser Production DMG Packaging & Distribution Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/Build/Products/Release"
APP_PATH="$BUILD_DIR/Holo Browser.app"
RELEASE_DIR="$PROJECT_DIR/Release"
DMG_STAGING="$PROJECT_DIR/Build/DMG_Staging"
DMG_NAME="HoloBrowser-1.0.0-RC7.dmg"
OUTPUT_DMG="$RELEASE_DIR/$DMG_NAME"
IDENTITY="${DEVELOPER_ID:--}"

echo "=========================================================="
echo "📦 Packaging Holo Browser RC7 Release DMG"
echo "=========================================================="

mkdir -p "$RELEASE_DIR"
mkdir -p "$DMG_STAGING"

# 1. (Skipped) Application Bundle should be built prior to calling this script
echo "=== Step 1: Skipping App Build (Expected to be built already) ==="

# 2. Prepare DMG Staging Folder
echo "=== Step 2: Preparing DMG Staging Content ==="
rm -rf "${DMG_STAGING:?}"/*
cp -R "$APP_PATH" "$DMG_STAGING/"

# Create Applications folder symlink for drag-and-drop installation
ln -s /Applications "$DMG_STAGING/Applications"

# Copy Documentation & Release Notes
cp "$PROJECT_DIR/Release/README_INSTALL.md" "$DMG_STAGING/README_INSTALL.md" 2>/dev/null || true
cp "$PROJECT_DIR/Release/CHANGELOG_RC2.md" "$DMG_STAGING/CHANGELOG.md" 2>/dev/null || true
cp "$PROJECT_DIR/Release/LICENSE.md" "$DMG_STAGING/LICENSE.md" 2>/dev/null || true
cp "$PROJECT_DIR/Release/SUPPORT.md" "$DMG_STAGING/SUPPORT.md" 2>/dev/null || true

# 3. Create Compressed DMG Archive (UDZO format)
echo "=== Step 3: Compressing DMG Volume ==="
rm -f "$OUTPUT_DMG"

hdiutil create -volname "Holo Browser Beta" \
  -srcfolder "$DMG_STAGING" \
  -ov -format UDZO \
  "$OUTPUT_DMG"

# 4. Code Sign DMG (if Developer ID available)
if [ "$IDENTITY" != "-" ]; then
    echo "=== Step 4: Signing DMG with Developer ID ==="
    codesign --force --timestamp --sign "$IDENTITY" "$OUTPUT_DMG"
fi

# 5. Run Verification Check
echo "=== Step 5: Verifying Release Package ==="
bash "$SCRIPT_DIR/verify_release.sh" "$APP_PATH"

echo "=========================================================="
echo "🎉 HOLO BROWSER DMG CREATED SUCCESSFULLY!"
echo "=========================================================="
echo "📍 DMG File: $OUTPUT_DMG"
echo "=========================================================="
