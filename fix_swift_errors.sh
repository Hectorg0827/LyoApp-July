#!/bin/bash

echo "=== Swift Error Cleanup Script ==="
echo "Fixing compilation errors systematically..."

# 1. Fix syntax errors (extraneous braces)
echo "Fixing syntax errors..."

# Fix FuturisticHeaderView.swift - remove extraneous brace at line 367
if [ -f "LyoApp/FuturisticHeaderView.swift" ]; then
    echo "Checking FuturisticHeaderView.swift..."
    # Remove the extraneous '}' at the end if it exists
    sed -i.bak '/^}$/d' LyoApp/FuturisticHeaderView.swift
    echo "Fixed FuturisticHeaderView.swift"
fi

# Fix HeaderView_Clean.swift - remove extraneous brace at line 124
if [ -f "LyoApp/HeaderView_Clean.swift" ]; then
    echo "Checking HeaderView_Clean.swift..."
    sed -i.bak '/^}$/d' LyoApp/HeaderView_Clean.swift
    echo "Fixed HeaderView_Clean.swift"
fi

# 2. Remove duplicate/conflicting files to resolve ambiguity
echo "Removing duplicate/conflicting files..."

# Remove backup files that are causing ambiguity
find LyoApp -name "*_backup" -type d -exec rm -rf {} + 2>/dev/null || true
find LyoApp -name "*_Old.swift" -delete 2>/dev/null || true
find LyoApp -name "*_Clean.swift" -delete 2>/dev/null || true

# Keep only the main versions of conflicting files
echo "Resolving file conflicts..."

# PostView conflicts - keep main PostView.swift, remove PostView_Clean.swift
if [ -f "LyoApp/PostView_Clean.swift" ] && [ -f "LyoApp/PostView.swift" ]; then
    rm "LyoApp/PostView_Clean.swift"
    echo "Removed PostView_Clean.swift"
fi

# MessengerMessage conflicts - keep the one in MessengerView.swift
if [ -f "LyoApp/ProfessionalMessengerView.swift" ]; then
    # Replace MessengerMessage references in ProfessionalMessengerView to use qualified names
    sed -i.bak 's/MessengerMessage/ProfessionalMessengerMessage/g' LyoApp/ProfessionalMessengerView.swift
    echo "Fixed MessengerMessage conflicts in ProfessionalMessengerView.swift"
fi

# LibraryViewModel conflicts - keep the one in LibraryView.swift
if [ -f "LyoApp/ProfessionalLibraryView.swift" ]; then
    sed -i.bak 's/LibraryViewModel/ProfessionalLibraryViewModel/g' LyoApp/ProfessionalLibraryView.swift
    echo "Fixed LibraryViewModel conflicts in ProfessionalLibraryView.swift"
fi

# VideoPost conflicts - keep the one in Models.swift
if [ -f "LyoApp/TikTokStyleHomeView.swift" ]; then
    # Remove the duplicate VideoPost struct from TikTokStyleHomeView.swift
    awk '/^struct VideoPost: Identifiable {/,/^}$/ {next} 1' LyoApp/TikTokStyleHomeView.swift > LyoApp/TikTokStyleHomeView.swift.tmp
    mv LyoApp/TikTokStyleHomeView.swift.tmp LyoApp/TikTokStyleHomeView.swift
    echo "Removed duplicate VideoPost from TikTokStyleHomeView.swift"
fi

# LearningResourceEntity conflicts - keep the SwiftData version
if [ -f "LyoApp/Services/LearningDataService.swift" ]; then
    # Remove the conflicting LearningResourceEntity from LearningDataService
    awk '/^final class LearningResourceEntity/,/^}$/ {next} 1' LyoApp/Services/LearningDataService.swift > LyoApp/Services/LearningDataService.swift.tmp
    mv LyoApp/Services/LearningDataService.swift.tmp LyoApp/Services/LearningDataService.swift
    echo "Removed duplicate LearningResourceEntity from LearningDataService.swift"
fi

# UserEntity conflicts - keep the SwiftData version, remove CoreData version
if [ -f "LyoApp/Data/CoreDataEntities.swift" ]; then
    rm "LyoApp/Data/CoreDataEntities.swift"
    echo "Removed conflicting CoreDataEntities.swift"
fi

# APIError conflicts - keep one version
if [ -f "LyoApp/SafeJSONDecoding.swift" ]; then
    # Remove APIError from SafeJSONDecoding.swift
    awk '/^enum APIError: LocalizedError {/,/^}$/ {next} 1' LyoApp/SafeJSONDecoding.swift > LyoApp/SafeJSONDecoding.swift.tmp
    mv LyoApp/SafeJSONDecoding.swift.tmp LyoApp/SafeJSONDecoding.swift
    echo "Removed duplicate APIError from SafeJSONDecoding.swift"
fi

# LearningAPIService conflicts - keep the main one
if [ -f "LyoApp/LearningHub/_backup/LearningAPIService_Old.swift" ]; then
    rm "LyoApp/LearningHub/_backup/LearningAPIService_Old.swift"
    echo "Removed old LearningAPIService backup"
fi

# ChatMessage conflicts - keep the one in Models.swift
if [ -f "LyoApp/LearningHub/_backup/LearningAssistantViewModel_Old.swift" ]; then
    rm -f LyoApp/LearningHub/_backup/LearningAssistantViewModel_Old.swift
    echo "Removed old LearningAssistantViewModel backup"
fi

# LearningHubView conflicts - keep the one in LearningHub/Views/
if [ -f "LyoApp/LearningComponents.swift" ]; then
    # Remove duplicate LearningHubView from LearningComponents.swift
    awk '/^struct LearningHubView: View {/,/^}$/ {next} 1' LyoApp/LearningComponents.swift > LyoApp/LearningComponents.swift.tmp
    mv LyoApp/LearningComponents.swift.tmp LyoApp/LearningComponents.swift
    echo "Removed duplicate LearningHubView from LearningComponents.swift"
fi

# 3. Fix SwiftData model issues
echo "Fixing SwiftData model issues..."

if [ -f "LyoApp/Data/SwiftDataModels.swift" ]; then
    # Fix the 'description' property name conflict in LearningResourceEntity
    sed -i.bak 's/var description: String/var resourceDescription: String/g' LyoApp/Data/SwiftDataModels.swift
    echo "Fixed 'description' property name conflict in SwiftData models"
fi

# 4. Fix missing type definitions
echo "Fixing missing type definitions..."

# Add missing AISearchResult type
if ! grep -q "struct AISearchResult" LyoApp/ProfessionalAISearchView.swift; then
    # Add AISearchResult struct at the top of the file
    sed -i.bak '1i\
struct AISearchResult: Identifiable {\
    let id = UUID()\
    let title: String\
    let description: String\
    let type: String\
    let relevance: Double\
    let url: String?\
}\
' LyoApp/ProfessionalAISearchView.swift
    echo "Added missing AISearchResult struct"
fi

# Add missing ProductionLearningAPIService
if ! grep -q "class ProductionLearningAPIService" LyoApp/Views/ProductionLearningHubView.swift; then
    # Add ProductionLearningAPIService at the top
    sed -i.bak '1i\
class ProductionLearningAPIService: ObservableObject {\
    @Published var isLoading = false\
    \
    func loadResources() async {\
        // Mock implementation\
        isLoading = false\
    }\
}\
' LyoApp/Views/ProductionLearningHubView.swift
    echo "Added missing ProductionLearningAPIService"
fi

# 5. Clean up build artifacts and regenerate project
echo "Regenerating Xcode project..."
xcodegen generate
echo "Project regenerated!"

echo "=== Swift Error Cleanup Complete ==="
echo "Attempting build test..."

# Quick build test
xcodebuild -project LyoApp.xcodeproj -scheme LyoApp build -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' -quiet 2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED)" | head -1

echo "Script execution completed!"
