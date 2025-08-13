#!/bin/bash

cd "$(dirname "$0")"

echo "Removing duplicate files..."

# Remove root LearnView.swift (keep the one in LearningHub/Views)
if [ -f "LyoApp/LearnView.swift" ]; then
    rm "LyoApp/LearnView.swift"
    echo "Removed root LearnView.swift"
fi

# Remove duplicate DataManager.swift in Data folder (keep DataPersistenceManager.swift)
if [ -f "LyoApp/Data/DataManager.swift" ]; then
    rm "LyoApp/Data/DataManager.swift" 
    echo "Removed Data/DataManager.swift"
fi

# Remove LearningAPIService_Fixed.swift from _backup folder (keep the one in Services)
if [ -f "LyoApp/LearningHub/_backup/LearningAPIService_Fixed.swift" ]; then
    rm "LyoApp/LearningHub/_backup/LearningAPIService_Fixed.swift"
    echo "Removed _backup/LearningAPIService_Fixed.swift"
fi

# Remove root LearningAssistantView.swift (keep the one in LearningHub/Views)
if [ -f "LyoApp/LearningAssistantView.swift" ]; then
    rm "LyoApp/LearningAssistantView.swift"
    echo "Removed root LearningAssistantView.swift"
fi

# Remove LearningAssistantViewModel_Fixed.swift from _backup folder (keep the one in ViewModels)
if [ -f "LyoApp/LearningHub/_backup/LearningAssistantViewModel_Fixed.swift" ]; then
    rm "LyoApp/LearningHub/_backup/LearningAssistantViewModel_Fixed.swift"
    echo "Removed _backup/LearningAssistantViewModel_Fixed.swift"
fi

# Remove root LearningHubView.swift (keep the one in LearningHub/Views)
if [ -f "LyoApp/LearningHubView.swift" ]; then
    rm "LyoApp/LearningHubView.swift"
    echo "Removed root LearningHubView.swift"
fi

# Remove LearningSearchViewModel.swift from Models directory (keep ViewModels version)
if [ -f "LyoApp/LearningHub/Models/LearningSearchViewModel.swift" ]; then
    rm "LyoApp/LearningHub/Models/LearningSearchViewModel.swift"
    echo "Removed Models/LearningSearchViewModel.swift"
fi

# Remove LearningSearchViewModel_Clean.swift from _backup folder (keep ViewModels version)
if [ -f "LyoApp/LearningHub/_backup/LearningSearchViewModel_Clean.swift" ]; then
    rm "LyoApp/LearningHub/_backup/LearningSearchViewModel_Clean.swift"
    echo "Removed _backup/LearningSearchViewModel_Clean.swift"
fi

# Remove LearningSearchViewModel_Fixed.swift from _backup folder (keep ViewModels version)
if [ -f "LyoApp/LearningHub/_backup/LearningSearchViewModel_Fixed.swift" ]; then
    rm "LyoApp/LearningHub/_backup/LearningSearchViewModel_Fixed.swift"
    echo "Removed _backup/LearningSearchViewModel_Fixed.swift"
fi

# Remove LioAI.swift duplicate (root version)
if [ -f "LyoApp/LioAI.swift" ] && [ -f "LyoApp/LearningHub/Services/LioAI.swift" ]; then
    rm "LyoApp/LioAI.swift"
    echo "Removed root LioAI.swift"
fi

# Remove LocalSearchService.swift duplicate (root version)
if [ -f "LyoApp/LocalSearchService.swift" ] && [ -f "LyoApp/LearningHub/Services/LocalSearchService.swift" ]; then
    rm "LyoApp/LocalSearchService.swift"
    echo "Removed root LocalSearchService.swift"
fi

# Remove RemoteAPI.swift duplicate (root version)
if [ -f "LyoApp/RemoteAPI.swift" ] && [ -f "LyoApp/LearningHub/Services/RemoteAPI.swift" ]; then
    rm "LyoApp/RemoteAPI.swift"
    echo "Removed root RemoteAPI.swift"
fi

# Remove SearchViewModel.swift duplicate (root version)
if [ -f "LyoApp/SearchViewModel.swift" ] && [ -f "LyoApp/LearningHub/ViewModels/SearchViewModel.swift" ]; then
    rm "LyoApp/SearchViewModel.swift"
    echo "Removed root SearchViewModel.swift"
fi

echo "Cleanup complete!"
echo "Regenerating project..."
xcodegen generate
echo "Project regenerated!"
