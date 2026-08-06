#!/usr/bin/env bash

# Holo Browser Release Build Automation Script
set -e

echo "=== Building Holo Browser (Production Release) ==="
cd "$(dirname "$0")/../HoloBrowser"

swift build -c release -Xswiftc -sdk -Xswiftc $(xcrun --show-sdk-path) -Xswiftc -strict-concurrency=complete

echo "✓ Production build completed successfully."
