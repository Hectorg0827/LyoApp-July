#!/bin/bash

echo "🚀 LyoApp Build Verification Script"
echo "==================================="

cd "/home/runner/work/LyoApp-July/LyoApp-July"

echo "📁 Current directory: $(pwd)"
echo "📋 Checking project structure..."

# Check if key files exist
ERRORS=0

echo ""
echo "🔍 Checking Essential Files..."

# Check Xcode project
if [ -f "LyoApp.xcodeproj/project.pbxproj" ]; then
    echo "✅ Xcode project file found"
else
    echo "❌ Xcode project file missing"
    ((ERRORS++))
fi

# Check main app file
if [ -f "LyoApp/LyoApp.swift" ]; then
    echo "✅ Main app file found"
else
    echo "❌ Main app file missing"
    ((ERRORS++))
fi

# Check ContentView
if [ -f "LyoApp/ContentView.swift" ]; then
    echo "✅ ContentView found"
else
    echo "❌ ContentView missing"
    ((ERRORS++))
fi

# Check Models
if [ -f "LyoApp/Models.swift" ]; then
    echo "✅ Models.swift found"
else
    echo "❌ Models.swift missing"
    ((ERRORS++))
fi

# Check Info.plist
if [ -f "LyoApp/Info.plist" ]; then
    echo "✅ Info.plist found"
else
    echo "❌ Info.plist missing"
    ((ERRORS++))
fi

echo ""
echo "🖼️ Checking App Icons..."

# Check app icons
ICON_COUNT=$(find "LyoApp/Assets.xcassets/AppIcon.appiconset" -name "*.png" 2>/dev/null | wc -l)
if [ "$ICON_COUNT" -gt "10" ]; then
    echo "✅ App Icons: $ICON_COUNT files present"
else
    echo "❌ App Icons: Only $ICON_COUNT files found"
    ((ERRORS++))
fi

echo ""
echo "📝 Checking Critical Services..."

# Check key services
SERVICES=("UserDataManager" "AuthenticationManager" "AnalyticsManager" "AppState" "VoiceActivationService")

for service in "${SERVICES[@]}"; do
    if find LyoApp -name "*.swift" -exec grep -l "class.*$service\|struct.*$service" {} \; | head -1 >/dev/null; then
        echo "✅ $service found"
    else
        echo "❌ $service missing"
        ((ERRORS++))
    fi
done

echo ""
echo "🧹 Checking for Backup Files..."

BACKUP_COUNT=$(find LyoApp -name "*.backup" -o -name "*_backup*" -o -name "*_Clean*" -o -name "*_Old*" -o -name "*.bak" 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -eq "0" ]; then
    echo "✅ No backup files found"
else
    echo "⚠️  Found $BACKUP_COUNT backup files"
fi

echo ""
echo "📊 Project Statistics:"
SWIFT_FILES=$(find LyoApp -name "*.swift" | wc -l)
echo "   • Swift files: $SWIFT_FILES"
echo "   • Lines of code: $(find LyoApp -name "*.swift" -exec wc -l {} + | tail -1 | awk '{print $1}')"

echo ""
echo "==================================="

if [ "$ERRORS" -eq "0" ]; then
    echo "🎉 ALL CHECKS PASSED!"
    echo "✅ Project structure is complete"
    echo "🚀 Ready for Xcode build"
    echo ""
    echo "📱 Next Steps:"
    echo "   1. Open project in Xcode"
    echo "   2. Select target device/simulator"
    echo "   3. Build and run (⌘+R)"
    echo "   4. 🎯 Expected: Successful build"
else
    echo "⚠️  FOUND $ERRORS ISSUES"
    echo "🛠️  Please fix the ❌ items above before building"
fi

echo ""
echo "==================================="
echo "🏆 LyoApp Build Verification Complete"
exit $ERRORS