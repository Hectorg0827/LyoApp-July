#!/bin/bash

# LyoApp Build Verification Script
# This script checks for common build issues and provides helpful feedback

echo "🔨 LyoApp Build Verification Starting..."
echo "📍 Working Directory: $(pwd)"
echo ""

# Check if we're in the correct directory
if [ ! -f "LyoApp.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: LyoApp.xcodeproj not found in current directory"
    echo "   Please run this script from the LyoApp project root"
    exit 1
fi

echo "✅ Project file found"

# Check for common problematic files
echo "🔍 Checking for problematic backup files..."

backup_files=$(find . -name "*backup*.swift" -o -name "*clean*.swift" -o -name "*_old*.swift" 2>/dev/null)
if [ -n "$backup_files" ]; then
    echo "⚠️  Found backup Swift files that might cause compilation issues:"
    echo "$backup_files"
    echo "   Consider moving these to a backup folder with .bak extension"
else
    echo "✅ No problematic backup files found"
fi

# Check for duplicate struct/class declarations
echo ""
echo "🔍 Checking for potential duplicate declarations..."

duplicate_check() {
    local pattern=$1
    local name=$2
    
    matches=$(grep -r "$pattern" --include="*.swift" . 2>/dev/null | grep -v "_backup" | grep -v ".bak" | wc -l)
    if [ "$matches" -gt 1 ]; then
        echo "⚠️  Found $matches declarations of $name:"
        grep -r "$pattern" --include="*.swift" . 2>/dev/null | grep -v "_backup" | grep -v ".bak"
    fi
}

duplicate_check "struct LearningCardView" "LearningCardView"
duplicate_check "struct SearchHeaderView" "SearchHeaderView"
duplicate_check "struct SearchResultsView" "SearchResultsView"
duplicate_check "struct FeaturedContentCarousel" "FeaturedContentCarousel"

# Check for missing required files
echo ""
echo "🔍 Checking for required service files..."

required_files=(
    "LyoApp/LocalSearchService.swift"
    "LyoApp/RemoteAPI.swift"
    "LyoApp/LioAI.swift"
    "LyoApp/CoreServices.swift"
    "LyoApp/AppStateExtensions.swift"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ Missing: $file"
    fi
done

echo ""
echo "🔨 Running build check..."

# Attempt to build (with timeout to prevent hanging)
timeout 60 xcodebuild -project LyoApp.xcodeproj -scheme LyoApp build -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' > build_output.tmp 2>&1

build_status=$?

if [ $build_status -eq 0 ]; then
    echo "🎉 BUILD SUCCESSFUL!"
    echo "   Your app compiled without errors"
elif [ $build_status -eq 124 ]; then
    echo "⏰ Build timed out after 60 seconds"
    echo "   This might indicate a hanging build process"
else
    echo "❌ BUILD FAILED"
    echo "   Showing last 20 lines of build output:"
    echo "----------------------------------------"
    tail -20 build_output.tmp
    echo "----------------------------------------"
    echo ""
    echo "   Full build log saved to: build_output.tmp"
    echo "   Common issues to check:"
    echo "   • Duplicate struct/class declarations"
    echo "   • Missing imports"
    echo "   • Syntax errors"
    echo "   • Access level issues (private vs public)"
fi

# Cleanup
rm -f build_output.tmp

echo ""
echo "📋 Build verification complete!"
