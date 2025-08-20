#!/bin/bash

cd "/Users/republicalatuya/Desktop/LyoApp July"

echo "=== Cleaning Xcode caches ==="
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*

echo "=== Killing any existing Xcode processes ==="
killall -9 xcodebuild 2>/dev/null || echo "No xcodebuild processes"
killall -9 Xcode 2>/dev/null || echo "No Xcode processes"

sleep 3

echo "=== Starting build test ==="
xcodebuild -project LyoApp.xcodeproj -scheme LyoApp build -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' > build_output.log 2>&1

echo "=== Build Status ==="
if tail -10 build_output.log | grep -q "BUILD SUCCEEDED"; then
    echo "BUILD SUCCEEDED ✅"
    tail -5 build_output.log
else
    echo "BUILD FAILED ❌"
    echo "=== Recent Errors ==="
    grep -E "(error:|BUILD FAILED)" build_output.log | tail -10
fi

echo "=== Done ==="
