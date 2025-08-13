#!/bin/bash

# Quick build test for LyoApp
echo "🔧 Testing LyoApp compilation..."

cd "/Users/republicalatuya/Desktop/LyoApp July"

echo "📋 Checking Swift files..."
find LyoApp -name "*.swift" | head -10

echo "🏗️ Starting build..."
xcodebuild -project LyoApp.xcodeproj -scheme LyoApp build -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' > build_test.log 2>&1

# Check result
if grep -q "BUILD SUCCEEDED" build_test.log; then
    echo "✅ BUILD SUCCEEDED!"
    echo "🎉 Your enhanced story creation feature is ready!"
elif grep -q "BUILD FAILED" build_test.log; then
    echo "❌ BUILD FAILED"
    echo "Errors found:"
    grep "error:" build_test.log | head -5
else
    echo "⏳ Build still in progress..."
fi

echo "📊 Build summary:"
tail -10 build_test.log
