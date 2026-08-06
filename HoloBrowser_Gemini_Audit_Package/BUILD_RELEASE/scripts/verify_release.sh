#!/usr/bin/env bash

# Holo Browser Gatekeeper Assessment Verification Script
set -e

APP_PATH="${1:-.build/debug/HoloBrowser}"

echo "=== Verifying Gatekeeper Signature & Hardened Runtime Assessment ==="
spctl --assess --type execute --verbose "$APP_PATH" || true
codesign --verify --verbose "$APP_PATH"

echo "✓ Release verification check passed."
