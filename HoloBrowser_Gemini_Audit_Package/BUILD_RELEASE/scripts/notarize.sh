#!/usr/bin/env bash

# Holo Browser Apple Notarization Upload Script
set -e

DMG_PATH="${1:-HoloBrowser.dmg}"
KEYCHAIN_PROFILE="${NOTARY_PROFILE:-HoloNotaryProfile}"

echo "=== Submitting $DMG_PATH to Apple Notarization Service ==="
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$KEYCHAIN_PROFILE" --wait

echo "=== Stapling Ticket to $DMG_PATH ==="
xcrun stapler staple "$DMG_PATH"

echo "✓ Notarization & Stapling completed."
