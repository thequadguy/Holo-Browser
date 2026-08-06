#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTLAB_DIR="$SCRIPT_DIR/HoloBrowserTestLab"

echo "🚀 Launching Holo Browser TESTLAB Automation Framework..."
echo "Directory: $TESTLAB_DIR"
echo ""

cd "$TESTLAB_DIR"
swift run HoloBrowserTestLab
