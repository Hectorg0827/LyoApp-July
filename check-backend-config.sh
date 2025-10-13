#!/bin/bash

# Check Backend Configuration Script

echo "======================================"
echo "LyoApp Backend Configuration Check"
echo "======================================"
echo ""

# Check if scheme has LYO_ENV set
SCHEME_PATH="$HOME/Library/Developer/Xcode/UserData/xcschemes"
WORKSPACE_PATH="/Users/hectorgarcia/Desktop/LyoApp July"

echo "1. Checking Xcode Scheme Configuration..."
echo ""

# Look for the scheme file
SCHEME_FILE="$WORKSPACE_PATH/LyoApp.xcodeproj/xcshareddata/xcschemes/LyoApp 1.xcscheme"
if [ -f "$SCHEME_FILE" ]; then
    echo "✅ Scheme file found"
    if grep -q "LYO_ENV" "$SCHEME_FILE"; then
        echo "✅ LYO_ENV found in scheme"
        grep -A 2 "LYO_ENV" "$SCHEME_FILE"
    else
        echo "❌ LYO_ENV NOT found in scheme"
        echo "   You need to add it in Xcode!"
    fi
else
    echo "⚠️  Scheme file not found at: $SCHEME_FILE"
    echo "   Checking user schemes..."
    USER_SCHEME="$SCHEME_PATH/LyoApp 1.xcscheme"
    if [ -f "$USER_SCHEME" ]; then
        echo "✅ User scheme found"
        if grep -q "LYO_ENV" "$USER_SCHEME"; then
            echo "✅ LYO_ENV found in user scheme"
        else
            echo "❌ LYO_ENV NOT found in user scheme"
        fi
    fi
fi

echo ""
echo "2. Checking API Environment Code..."
echo ""

# Check APIEnvironment.swift
API_ENV_FILE="$WORKSPACE_PATH/LyoApp/Core/Networking/APIEnvironment.swift"
if [ -f "$API_ENV_FILE" ]; then
    echo "✅ APIEnvironment.swift found"
    echo ""
    echo "Production URL:"
    grep "lyo-backend" "$API_ENV_FILE" | head -1
    echo ""
    echo "Local URL:"
    grep "localhost:8000" "$API_ENV_FILE" | head -1
else
    echo "❌ APIEnvironment.swift not found"
fi

echo ""
echo "======================================"
echo "DIAGNOSIS"
echo "======================================"
echo ""
echo "Based on your screenshot showing 'fallback mode':"
echo ""
echo "❌ The app is NOT connected to the real backend"
echo ""
echo "Most likely causes:"
echo "1. LYO_ENV=prod is NOT set in Xcode scheme"
echo "2. App is trying to connect to localhost:8000"
echo "3. localhost:8000 is not running (expected)"
echo "4. Falls back to mock responses"
echo ""
echo "======================================"
echo "SOLUTION"
echo "======================================"
echo ""
echo "📋 Follow these steps:"
echo ""
echo "1. Open Xcode"
echo "2. Go to: Product → Scheme → Edit Scheme..."
echo "3. Select 'Run' in left sidebar"
echo "4. Click 'Arguments' tab"
echo "5. Under 'Environment Variables', click '+'"
echo "6. Add:"
echo "   Name:  LYO_ENV"
echo "   Value: prod"
echo "   [✓] Check the box"
echo "7. Click 'Close'"
echo "8. DELETE the app from your iPhone"
echo "9. Run again from Xcode (Cmd+R)"
echo ""
echo "Expected console output after fix:"
echo "🌐 Backend: https://lyo-backend-830162750094.us-central1.run.app"
echo "✅ Using PRODUCTION backend"
echo ""
echo "======================================"
