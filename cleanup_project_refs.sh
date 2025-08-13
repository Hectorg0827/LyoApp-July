#!/bin/bash

# Cleanup Xcode project references to deleted files
cd "/Users/republicalatuya/Desktop/LyoApp July"

echo "Creating backup of project.pbxproj..."
cp LyoApp.xcodeproj/project.pbxproj LyoApp.xcodeproj/project.pbxproj.backup.$(date +%Y%m%d_%H%M%S)

echo "Removing references to deleted files..."

# List of deleted files that may still be referenced
DELETED_FILES=(
    "CoreDataEntities.swift"
    "PostView_Clean.swift" 
    "APIIntegrationPlan.swift"
    "LyoAPIService_Clean.swift"
    "HeaderView_Clean.swift"
    "LearnTabView_Clean.swift"
    "LearnTabView_Enhanced.swift"
    "LearnTabView_Fixed.swift"
    "LearningSearchViewModel_Clean.swift"
    "LearningSearchViewModel_Fixed.swift"
    "LearningAssistantViewModel_Fixed.swift"
    "SearchComponents_clean.swift"
    "AppStoreScreenshots.swift"
    "_backup"
)

# Remove references to these files from project.pbxproj
for file in "${DELETED_FILES[@]}"; do
    echo "Removing references to $file..."
    # Remove lines containing the file reference (but keep structure intact)
    sed -i.tmp "/.*${file}.*fileRef.*=.*$/d" LyoApp.xcodeproj/project.pbxproj
    sed -i.tmp "/.*${file}.*isa.*PBXFileReference.*$/d" LyoApp.xcodeproj/project.pbxproj
    sed -i.tmp "/.*${file}.*path.*=.*$/d" LyoApp.xcodeproj/project.pbxproj
    sed -i.tmp "/.*${file}.*sourceTree.*=.*$/d" LyoApp.xcodeproj/project.pbxproj
done

# Clean up temporary files
rm -f LyoApp.xcodeproj/project.pbxproj.tmp

echo "Project reference cleanup completed!"

# Test build to see if references were cleaned
echo "Testing build..."
timeout 30 xcodebuild -project LyoApp.xcodeproj -scheme LyoApp build -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' 2>&1 | tail -5
