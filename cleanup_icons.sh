#!/bin/bash

echo "🧹 Cleaning Up App Icon Files"
echo "=============================="

ICON_DIR="/Users/republicalatuya/Desktop/LyoApp July/LyoApp/Assets.xcassets/AppIcon.appiconset"

echo "📁 Icon directory: $ICON_DIR"
echo ""

echo "📋 Files before cleanup:"
ls -la "$ICON_DIR" | grep ".png"
echo ""

echo "🗑️  Removing extra underscore-named files..."

# Remove all files with underscore naming (not referenced in Contents.json)
rm -f "$ICON_DIR/icon_"*.png

echo ""
echo "✅ Files after cleanup:"
ls -la "$ICON_DIR" | grep ".png"
echo ""

FINAL_COUNT=$(ls -la "$ICON_DIR" | grep ".png" | wc -l | tr -d ' ')
echo "📊 Final icon count: $FINAL_COUNT files"

if [ "$FINAL_COUNT" -eq "9" ]; then
    echo "✅ Perfect! Exactly 9 icons as expected by Contents.json"
else
    echo "⚠️  Expected 9 icons, found $FINAL_COUNT"
fi

echo ""
echo "🎯 App icon cleanup complete!"
