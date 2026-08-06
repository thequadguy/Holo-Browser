#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🚀 Launching Holo Browser TESTLAB Automation Framework..."
echo ""

swift run HoloBrowserTestLab
