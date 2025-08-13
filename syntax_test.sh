#!/bin/bash

echo "🔍 Testing HeaderView.swift compilation..."

# Test just the HeaderView file
cd "/Users/republicalatuya/Desktop/LyoApp July"

echo "⚡ Quick syntax check..."
xcrun swift -frontend -typecheck LyoApp/HeaderView.swift -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk 2>&1

if [ $? -eq 0 ]; then
    echo "✅ HeaderView.swift syntax is correct!"
    echo "✅ Material/Color type issue fixed!"
else
    echo "❌ Still has syntax issues"
fi

echo ""
echo "🎯 Testing specific Material usage..."
grep -n "ultraThinMaterial" LyoApp/HeaderView.swift
