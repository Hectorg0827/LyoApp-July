#!/bin/bash

ICON_DIR="/Users/republicalatuya/Desktop/LyoApp July/LyoApp/Assets.xcassets/AppIcon.appiconset"

echo "🧹 FIXING APP ICON UNASSIGNED CHILDREN ERROR"
echo "============================================="

cd "$ICON_DIR"

echo "📊 Before cleanup:"
ls -1 *.png | wc -l | tr -d ' '

echo ""
echo "🗑️  Removing extra files not referenced in Contents.json..."

# Remove all files that use underscore naming
for file in icon_*.png; do
    if [ -f "$file" ]; then
        echo "Removing: $file"
        rm "$file"
    fi
done

echo ""
echo "📊 After cleanup:"
ls -1 *.png | wc -l | tr -d ' '

echo ""
echo "✅ Final icon files (should match Contents.json references):"
ls -1 *.png

echo ""
echo "🎯 App icon cleanup complete!"
echo "Only files referenced in Contents.json should remain."
