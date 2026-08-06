#!/usr/bin/env bash

# Holo Browser Code Signing Automation Script
set -e

APP_PATH="${1:-.build/release/HoloBrowser}"
IDENTITY="${DEVELOPER_ID:-Developer ID Application: Holo Browser Inc}"

echo "=== Signing Holo Browser Bundle with Hardened Runtime ==="
codesign --force --options runtime --deep --sign "$IDENTITY" "$APP_PATH"

echo "✓ Code signing completed."
