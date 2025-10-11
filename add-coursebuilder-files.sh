#!/bin/bash

# Script to add CourseBuilder files to Xcode project
# Run this from the project root directory

set -e  # Exit on error

echo "🎯 Adding CourseBuilder files to Xcode project..."
echo ""

PROJECT_DIR="/Users/hectorgarcia/Desktop/LyoApp July"
cd "$PROJECT_DIR"

# Check if files exist
echo "📋 Checking files..."
FILES_TO_ADD=(
    "LyoApp/Views/CourseBuilderView.swift"
    "LyoApp/Views/CourseCreationView.swift"
    "LyoApp/Views/CourseGeneratingView.swift"
    "LyoApp/Views/CoursePreferencesView.swift"
    "LyoApp/Views/CourseProgressDetailView.swift"
    "LyoApp/ViewModels/CourseBuilderCoordinator.swift"
)

for file in "${FILES_TO_ADD[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ Found: $file"
    else
        echo "❌ Missing: $file"
        exit 1
    fi
done

echo ""
echo "🔧 Method 1: Manual Xcode Addition (RECOMMENDED)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Please follow these steps in Xcode:"
echo ""
echo "1️⃣  Open Xcode (if not already open)"
echo "2️⃣  In the left sidebar (Project Navigator), find the 'Views' folder"
echo "3️⃣  Right-click on 'Views' → 'Add Files to \"LyoApp\"...'"
echo "4️⃣  Navigate to: $PROJECT_DIR/LyoApp/Views"
echo "5️⃣  Select these 5 files:"
echo "    • CourseBuilderView.swift"
echo "    • CourseCreationView.swift"
echo "    • CourseGeneratingView.swift"
echo "    • CoursePreferencesView.swift"
echo "    • CourseProgressDetailView.swift"
echo "6️⃣  ✅ CHECK: 'Add to targets: LyoApp' is checked"
echo "7️⃣  ✅ CHECK: 'Copy items if needed' is UNCHECKED (files already in place)"
echo "8️⃣  Click 'Add'"
echo ""
echo "9️⃣  Right-click on 'ViewModels' folder → 'Add Files to \"LyoApp\"...'"
echo "🔟 Navigate to: $PROJECT_DIR/LyoApp/ViewModels"
echo "1️⃣1️⃣ Select: CourseBuilderCoordinator.swift"
echo "1️⃣2️⃣ ✅ CHECK: 'Add to targets: LyoApp' is checked"
echo "1️⃣3️⃣ Click 'Add'"
echo ""
echo "1️⃣4️⃣ Build the project: Press ⌘ + B"
echo "1️⃣5️⃣ Look for 'Build Succeeded ✅'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  IMPORTANT: This is the safest method to avoid breaking the Xcode project!"
echo ""

read -p "Press Enter when you've added the files in Xcode, and I'll verify the build... "

echo ""
echo "🔍 Verifying files were added..."

# Check if files are now in the project
if grep -q "CourseBuilderView.swift" LyoApp.xcodeproj/project.pbxproj; then
    echo "✅ CourseBuilderView.swift added to project"
else
    echo "❌ CourseBuilderView.swift NOT found in project"
fi

if grep -q "CourseBuilderCoordinator.swift" LyoApp.xcodeproj/project.pbxproj; then
    echo "✅ CourseBuilderCoordinator.swift added to project"
else
    echo "❌ CourseBuilderCoordinator.swift NOT found in project"
fi

echo ""
echo "🏗️  Building project..."
xcodebuild -project LyoApp.xcodeproj -scheme "LyoApp 1" build -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | tail -10

echo ""
echo "✅ Done! Check the build results above."
