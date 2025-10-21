#!/bin/bash

# Quick verification script to check if CourseBuilder files are in the Xcode project

echo "🔍 Checking if CourseBuilder files are in Xcode project..."
echo ""

PROJECT_FILE="LyoApp.xcodeproj/project.pbxproj"

check_file() {
    local filename=$1
    if grep -q "$filename" "$PROJECT_FILE"; then
        echo "✅ $filename"
        return 0
    else
        echo "❌ $filename - NOT IN PROJECT"
        return 1
    fi
}

cd "/Users/hectorgarcia/Desktop/LyoApp July"

all_good=true

echo "📁 Views:"
check_file "CourseBuilderView.swift" || all_good=false
check_file "CourseCreationView.swift" || all_good=false
check_file "CourseGeneratingView.swift" || all_good=false
check_file "CoursePreferencesView.swift" || all_good=false
check_file "CourseProgressDetailView.swift" || all_good=false

echo ""
echo "📁 ViewModels:"
check_file "CourseBuilderCoordinator.swift" || all_good=false

echo ""
echo "📁 Already in project:"
check_file "CourseBuilderFlowView.swift" || all_good=false
check_file "CourseBuilderModels.swift" || all_good=false

echo ""
if [ "$all_good" = true ]; then
    echo "🎉 All CourseBuilder files are in the project!"
    echo ""
    echo "Now building to verify..."
    xcodebuild -project LyoApp.xcodeproj -scheme "LyoApp 1" build -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED)" | tail -1
else
    echo "⚠️  Some files are missing from the Xcode project."
    echo "Please add them manually using Xcode's 'Add Files to LyoApp...' feature."
fi
