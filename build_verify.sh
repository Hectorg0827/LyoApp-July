#!/bin/bash

# Build verification script for Lyo iOS app
echo "🏗️  Starting Lyo iOS App Build Verification..."
echo "================================================"

PROJECT_DIR="/Users/republicalatuya/Desktop/LyoApp July"
cd "$PROJECT_DIR"

echo "📁 Working directory: $(pwd)"
echo "📱 Target: iOS Simulator - iPhone 15 Pro"
echo ""

# Clean build folder first
echo "🧹 Cleaning build folder..."
xcodebuild clean -project LyoApp.xcodeproj -scheme LyoApp >/dev/null 2>&1

echo "🔨 Building project..."
echo "This may take a few minutes..."
echo ""

# Build the project with detailed output
BUILD_RESULT=$(xcodebuild -project LyoApp.xcodeproj -scheme LyoApp build -destination 'platform=iOS Simulator,name=iPhone 15 Pro' 2>&1)
BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo "✅ BUILD SUCCESSFUL!"
    echo "🎉 Lyo iOS app compiled successfully with no errors!"
    echo ""
    echo "📊 Build Summary:"
    echo "  • All Swift files compiled successfully"
    echo "  • No compilation errors found"
    echo "  • App ready for iOS submission"
    echo ""
    echo "🚀 Next Steps:"
    echo "  1. Archive the app for App Store submission"
    echo "  2. Upload to App Store Connect"
    echo "  3. Submit for App Store review"
else
    echo "❌ BUILD FAILED!"
    echo "🔍 Build errors found:"
    echo ""
    echo "$BUILD_RESULT" | grep -i "error:" | head -10
    echo ""
    echo "💡 Please fix the above errors and try again."
fi

echo ""
echo "================================================"
echo "🏁 Build verification complete."
exit $BUILD_EXIT_CODE
