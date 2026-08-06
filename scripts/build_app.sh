#!/usr/bin/env bash

# Holo Browser Production Application Bundle Assembly Script
# Features: Dual-Architecture (Universal Binary arm64 + x86_64), Info.plist, Code Signing, Entitlements, Default Browser Registration.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOLO_DIR="$ROOT_DIR/HoloBrowser"
APP_NAME="Holo Browser.app"
OUTPUT_DIR="$ROOT_DIR/Build/Products/Release"
APP_BUNDLE="$OUTPUT_DIR/$APP_NAME"

APP_VERSION="1.0.0-rc7"
BUILD_NUMBER="700"

echo "=========================================================="
echo "🚀 Building Holo Browser $APP_VERSION (Build $BUILD_NUMBER)"
echo "=========================================================="

cd "$HOLO_DIR"

# 1. Compile arm64 target
echo "🛠 Compiling arm64 slice..."
xcrun --sdk macosx swift build -c release --triple arm64-apple-macosx14.0

# 2. Compile x86_64 target
echo "🛠 Compiling x86_64 slice..."
xcrun --sdk macosx swift build -c release --triple x86_64-apple-macosx14.0

# 3. Assemble macOS App Bundle
echo "📦 Assembling macOS App Bundle structure..."
mkdir -p "$OUTPUT_DIR"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

ARM64_BIN="$HOLO_DIR/.build/arm64-apple-macosx/release/HoloBrowser"
X86_64_BIN="$HOLO_DIR/.build/x86_64-apple-macosx/release/HoloBrowser"
UNIVERSAL_BIN="$APP_BUNDLE/Contents/MacOS/HoloBrowser"

if [ -f "$ARM64_BIN" ] && [ -f "$X86_64_BIN" ]; then
    echo "🔀 Creating Universal Binary (arm64 + x86_64) with lipo..."
    lipo -create "$ARM64_BIN" "$X86_64_BIN" -output "$UNIVERSAL_BIN"
elif [ -f "$ARM64_BIN" ]; then
    echo "⚠️ x86_64 slice missing. Using arm64 slice..."
    cp "$ARM64_BIN" "$UNIVERSAL_BIN"
elif [ -f "$X86_64_BIN" ]; then
    echo "⚠️ arm64 slice missing. Using x86_64 slice..."
    cp "$X86_64_BIN" "$UNIVERSAL_BIN"
else
    echo "❌ Error: Neither arm64 nor x86_64 compiled binary was found!"
    exit 1
fi

chmod +x "$UNIVERSAL_BIN"

# 4. Write PkgInfo
echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# 5. Write Complete Info.plist (including CFBundleURLTypes for Default Browser registration)
echo "📝 Writing Info.plist with Default Browser CFBundleURLTypes..."
cat << EOF > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>HoloBrowser</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.holobrowser.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Holo Browser</string>
    <key>CFBundleDisplayName</key>
    <string>Holo Browser</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Holo Browser Team. All rights reserved.</string>
    
    <!-- CFBundleURLTypes: Default macOS HTTP/HTTPS Protocol Registration -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>Web site URL</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>http</string>
                <string>https</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

# 6. Copy AppIcon if available
if [ -f "$ROOT_DIR/Resources/AppIcon.icns" ]; then
    cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    echo "✓ AppIcon.icns copied."
fi

# 7. Code Sign Bundle
echo "🔒 Executing Code Signing Pipeline..."
bash "$SCRIPT_DIR/sign_app.sh" "$APP_BUNDLE"

echo "=========================================================="
echo "🎉 APPLICATION BUNDLE SUCCESSFULLY CREATED!"
echo "=========================================================="
echo "📍 Location: $APP_BUNDLE"
file "$UNIVERSAL_BIN"
echo "=========================================================="

# 8. Verify Release
echo "🔍 Verifying App Bundle..."
bash "$SCRIPT_DIR/verify_release.sh" "$APP_BUNDLE"

# 9. Sync to Desktop
DESKTOP_APP="$HOME/Desktop/Holo Browser.app"
echo "🔄 Synchronizing to Desktop: $DESKTOP_APP"
rm -rf "$DESKTOP_APP"
cp -a "$APP_BUNDLE" "$HOME/Desktop/"

echo "✅ Desktop sync complete. Verification:"
stat "$DESKTOP_APP" | grep -E "Modify|Access" || true

# 10. Build DMG
echo "💿 Building Release DMG..."
bash "$SCRIPT_DIR/build_dmg.sh"

echo "✅ Final Verification Complete. Desktop and DMG are ready!"

