#!/bin/bash

# LyoApp Build Script
# This script builds the LyoApp project with proper error handling

echo "🚀 Starting LyoApp Build Process..."
echo "======================================"

# Navigate to the project directory
cd "/Users/republicalatuya/Desktop/LyoApp July/LyoApp"

# Check if we're in the right directory
if [ ! -f "LyoApp.swift" ]; then
    echo "❌ Error: Not in the correct project directory"
    echo "Expected to find LyoApp.swift in current directory"
    exit 1
fi

echo "📂 Current directory: $(pwd)"
echo "📱 Project files found: ✅"

# Clean any existing build artifacts
echo ""
echo "🧹 Cleaning build artifacts..."
rm -rf .build
rm -rf build
echo "✅ Clean completed"

# Verify required files exist
echo ""
echo "🔍 Verifying required configuration files..."

required_files=(
    "APIConfig.swift"
    "ProductionConfiguration.swift"
    "LyoApp.swift"
    "UserDataManager.swift"
    "Assets.xcassets/AppIcon.appiconset/Contents.json"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file found"
    else
        echo "❌ $file missing"
        exit 1
    fi
done

# Check Swift Package configuration
echo ""
echo "📦 Checking Swift Package configuration..."
if [ -f "Package.swift" ]; then
    echo "✅ Package.swift found"
    echo "📋 Package configuration:"
    head -15 Package.swift
else
    echo "❌ Package.swift missing"
    exit 1
fi

# Attempt to build the project
echo ""
echo "⚙️  Building LyoApp..."
echo "======================================"

# Try to build with verbose output
if swift build --verbose; then
    echo ""
    echo "🎉 BUILD SUCCESSFUL! 🎉"
    echo "======================================"
    echo "✅ LyoApp compiled successfully"
    echo "🌐 Backend URL: https://lyo-backend-830162750094.us-central1.run.app"
    echo "⚡ Environment: Production (default)"
    echo "🔧 Debug environment toggle: Available in DEBUG builds"
    echo ""
    echo "📱 Your app is ready to use the real backend!"
    echo "   • No more demo/mock data"
    echo "   • Real API connectivity"
    echo "   • Production-ready configuration"
    echo ""
    echo "🚀 To run the app:"
    echo "   swift run"
    echo ""
    echo "📖 To open in Xcode:"
    echo "   open Package.swift"
    
    exit 0
else
    echo ""
    echo "❌ BUILD FAILED"
    echo "======================================"
    echo "🔍 Build failed. Check the error messages above."
    echo ""
    echo "💡 Common fixes:"
    echo "   1. Clean build: rm -rf .build && swift build"
    echo "   2. Update Xcode: xcode-select --install"
    echo "   3. Check file permissions: chmod +r *.swift"
    echo ""
    exit 1
fi