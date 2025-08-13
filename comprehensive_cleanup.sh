#!/bin/bash

# Comprehensive cleanup script for LyoApp build issues
echo "🧹 Starting comprehensive cleanup of LyoApp..."

cd "/Users/republicalatuya/Desktop/LyoApp July"

echo "📁 Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/LyoApp-*

echo "🗑️ Removing duplicate and problematic files..."

# Remove all DataManager duplicates
find LyoApp -name "DataManager.swift" -delete
echo "✅ Removed all DataManager.swift duplicates"

# Remove all Core Data model files temporarily
rm -rf LyoApp/Data/LyoApp.xcdatamodeld
echo "✅ Removed Core Data model (temporary)"

# Remove all *_Clean files
find LyoApp -name "*_Clean.swift" -delete
echo "✅ Removed *_Clean files"

# Remove all *_Old files
find LyoApp -name "*_Old.swift" -delete
echo "✅ Removed *_Old files"

# Remove duplicate LearningAssistantView files (keep the one in LearningHub/Views)
if [ -f "LyoApp/LearningAssistantView.swift" ] && [ -f "LyoApp/LearningHub/Views/LearningAssistantView.swift" ]; then
    rm "LyoApp/LearningAssistantView.swift"
    echo "✅ Removed duplicate LearningAssistantView.swift"
fi

# Remove duplicate LearningHubView files
find LyoApp -name "LearningHubView.swift" | head -n -1 | xargs -r rm
echo "✅ Removed duplicate LearningHubView files"

# Remove duplicate LearningSearchViewModel files
find LyoApp -name "LearningSearchViewModel.swift" | head -n -1 | xargs -r rm
echo "✅ Removed duplicate LearningSearchViewModel files"

# Remove any _backup directories that might be causing issues
rm -rf LyoApp/LearningHub/_backup
rm -rf LyoApp/*/_backup
echo "✅ Removed _backup directories"

# Remove any empty directories
find LyoApp -type d -empty -delete
echo "✅ Removed empty directories"

echo "🔨 Regenerating Xcode project..."
xcodegen generate

echo "🎯 Testing build..."
timeout 30 xcodebuild -project LyoApp.xcodeproj -scheme LyoApp build -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' 2>&1 | grep -E '(BUILD SUCCEEDED|BUILD FAILED|error:)' | head -5

echo "✅ Cleanup complete!"
