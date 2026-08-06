#!/bin/bash

echo "🚀 HOLO BROWSER QA CERTIFICATION STARTED"
echo "======================================"

PROJECT="/Users/jake/Desktop/Holo Browser/HoloBrowser"
QA="/Users/jake/HoloBrowser-QA"

cd "$PROJECT"

echo ""
echo "🧪 Running Swift Tests..."
swift test

if [ $? -ne 0 ]; then
    echo "❌ Swift Tests FAILED"
else
    echo "✅ Swift Tests PASSED"
fi


echo ""
echo "🖥️ Running Holo App Launch Tests..."

cd "$QA"

npx playwright test

if [ $? -ne 0 ]; then
    echo "❌ Playwright Tests FAILED"
else
    echo "✅ Playwright Tests PASSED"
fi


echo ""
echo "======================================"
echo "🎉 HOLO QA CERTIFICATION COMPLETE"
echo "Report:"
echo "http://localhost:9323/"
