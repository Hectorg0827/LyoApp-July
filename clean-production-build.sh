#!/bin/bash
# Clean production build script for LyoApp

echo "🧹 === Cleaning LyoApp for Production Build ==="

# Navigate to project directory
cd "/Users/hectorgarcia/Desktop/LyoApp July"

# Clean all build artifacts
echo "🗑️  Cleaning build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/LyoApp-*
rm -rf .build
rm -rf build

# Clean Xcode project
if [ -f "LyoApp.xcodeproj" ]; then
    echo "🧽 Cleaning Xcode project..."
    xcodebuild clean -project LyoApp.xcodeproj -scheme LyoApp -configuration Debug
fi

echo ""
echo "🔨 === Building Production Version ==="
echo "📋 Configuration: Debug (with Production Backend)"
echo "🌐 Backend: https://lyo-backend-830162750094.us-central1.run.app"
echo "🚫 Mock Data: DISABLED"
echo ""

# Build the project
echo "⚙️  Starting build process..."
xcodebuild -project LyoApp.xcodeproj -scheme LyoApp -configuration Debug build

BUILD_STATUS=$?

echo ""
if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ === BUILD SUCCESSFUL ==="
    echo "🎯 LyoApp built successfully!"
    echo "🌐 Configured for production backend only"
    echo "🚫 No mock/demo data"
    echo ""
    echo "📱 Next Steps:"
    echo "1. Open LyoApp.xcodeproj in Xcode"
    echo "2. Run the app (⌘+R)"
    echo "3. Check console for production configuration confirmation"
    echo "4. Verify no mock data appears in feed"
else
    echo "❌ === BUILD FAILED ==="
    echo "Please check the build errors above"
    exit 1
fi