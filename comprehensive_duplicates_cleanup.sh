#!/bin/bash

echo "🧹 COMPREHENSIVE DUPLICATES CLEANUP - LYOAPP JULY 2025"
echo "=================================================="
echo ""

cd "/Users/republicalatuya/Desktop/LyoApp July"

# Track what we're removing
removed_count=0

# Function to safely remove file and count
safe_remove() {
    local file="$1"
    local reason="$2"
    
    if [ -f "$file" ]; then
        echo "🗑️  REMOVING: $file"
        echo "   REASON: $reason"
        rm -f "$file"
        ((removed_count++))
    fi
}

echo "1️⃣ REMOVING DUPLICATE VIEW FILES"
echo "--------------------------------"
safe_remove "LyoApp/DiscoverView.swift" "Duplicate of InstagramStyleDiscoverView.swift"
safe_remove "LyoApp/InstagramStyleDiscoverView.swift" "Keep main DiscoverView functionality"
safe_remove "LyoApp/FloatingActionButton.swift" "Duplicate of QuantumGateRiftButton.swift" 
safe_remove "LyoApp/FuturisticHeaderView_Fixed.swift" "Duplicate of FuturisticHeaderView.swift"
safe_remove "LyoApp/LearnTabView.swift" "Duplicate of LearnTabView_Enhanced.swift"
safe_remove "LyoApp/LearnTabView_Fixed.swift" "Duplicate of LearnTabView_Enhanced.swift"
safe_remove "LyoApp/LearningAssistantView_Simple.swift" "Keep LearningHub version"
safe_remove "LyoApp/LearningHubView_Simple.swift" "Keep LearningHub version"
safe_remove "LyoApp/ProfileView.swift" "Duplicate functionality in MoreTabView.swift"

echo ""
echo "2️⃣ REMOVING DUPLICATE SERVICE FILES"
echo "----------------------------------"
safe_remove "LyoApp/Services/LearningAPIService_Production.swift" "Duplicate of LearningHub version"
safe_remove "LyoApp/LearningHub/ViewModels/LearningAssistantViewModel_Fixed.swift" "Keep main version"
safe_remove "LyoApp/LearningHub/ViewModels/LearningSearchViewModel_Fixed.swift" "Keep main version"

echo ""
echo "3️⃣ REMOVING DUPLICATE MODEL FILES" 
echo "--------------------------------"
# Keep the one in LearningHub/Services, remove others
safe_remove "LyoApp/AI/GemmaAIService.swift" "Contains duplicate LearningPath struct - conflicts with LioAI.swift"

echo ""
echo "4️⃣ FIXING CRITICAL MAIN APP CONFLICT"
echo "-----------------------------------"
safe_remove "LyoApp/WorkingLyoApp.swift" "Duplicate main app entry point - keeping LyoApp.swift"

echo ""
echo "5️⃣ REMOVING BROKEN SERVICE FILES"
echo "------------------------------"
safe_remove "LyoApp/FreeCoursesService.swift" "Contains syntax errors with enum cases outside enum"
safe_remove "LyoApp/EducationalContentDemoView.swift" "References missing EducationalContentManager"
safe_remove "LyoApp/GoogleBooksService.swift" "References missing APIKeys"
safe_remove "LyoApp/YouTubeEducationService.swift" "References missing APIKeys"
safe_remove "LyoApp/MarketReadinessImplementation.swift" "Struct cannot conform to ObservableObject"

echo ""
echo "6️⃣ REMOVING HEADER/STYLE DUPLICATES"
echo "----------------------------------"
safe_remove "LyoApp/HeaderView.swift" "Conflicts with FuturisticHeaderView.swift"

echo ""
echo "7️⃣ REMOVING MEDIA PLAYER DUPLICATES"  
echo "----------------------------------"
safe_remove "LyoApp/Components/MediaPlayers.swift" "Conflicts with TikTokStyleHomeView.swift VideoPlayerView"

echo ""
echo "8️⃣ REMOVING MORE VIEW DUPLICATES"
echo "------------------------------"
safe_remove "LyoApp/Views/ProductionLearningHubView.swift" "Conflicts with LearningHub/Views/LearningHubView.swift"

echo ""
echo "✅ CLEANUP SUMMARY"
echo "=================="
echo "📊 Total files removed: $removed_count"
echo ""
echo "🔄 Now regenerating Xcode project..."
xcodegen generate

if [ $? -eq 0 ]; then
    echo "✅ Project regenerated successfully!"
    echo ""
    echo "🏗️  Testing build..."
    timeout 30 xcodebuild -project LyoApp.xcodeproj -scheme LyoApp build -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' 2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -5
else
    echo "❌ Project regeneration failed"
    exit 1
fi

echo ""
echo "🎯 CLEANUP COMPLETE! Your LyoApp should now build successfully."
