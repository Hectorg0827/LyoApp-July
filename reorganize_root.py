#!/usr/bin/env python3
"""
Intelligent folder reorganization
Moves files from root to proper folders based on their purpose
"""

import os
import shutil
from pathlib import Path

LYOAPP_PATH = "/Users/hectorgarcia/Desktop/LyoApp July/LyoApp"

# Files that MUST stay in root (entry points and main app structure)
ROOT_KEEPERS = [
    "LyoApp.swift",  # App entry point
    "ContentView.swift",  # Main tab view
    "AppState.swift",  # Global state
    "AppStateExtensions.swift",  # Global state extensions
    "DesignSystem.swift",  # Design system
    "DesignTokens.swift",  # Design tokens
]

# Reorganization rules: source_file -> destination_folder
REORGANIZATION_MAP = {
    # Views -> Views folder
    "AIAvatarView.swift": "Views/",
    "AIOnboardingFlowView.swift": "Views/",
    "AISearchView.swift": "Views/",
    "AuthenticationView.swift": "Views/",
    "AvatarHeadView.swift": "Views/",
    "ClassroomHubView.swift": "Views/",
    "CommunityView.swift": "Views/",
    "ContentCardDrawer.swift": "Views/",
    "ConversationBubbleView.swift": "Views/",
    "ConversationFlowView.swift": "Views/",
    "ExploreTabView.swift": "Views/",
    "HomeView.swift": "Views/",
    "MessengerView.swift": "Views/",
    "MoreTabView.swift": "Views/",
    "NotificationView.swift": "Views/",
    "ProfileView.swift": "Views/",
    "ResourceCurationBar.swift": "Views/",
    "SettingsView.swift": "Views/",
    "StoryView.swift": "Views/",
    "VideoView.swift": "Views/",
    
    # Models -> Models folder
    "AIModels.swift": "Models/",
    "APIResponseModels.swift": "Models/",
    "LearningComponents.swift": "Models/",
    "LearningResource.swift": "Models/",
    "LessonModels.swift": "Models/",
    "TypeDefinitions.swift": "Models/",
    
    # Services -> Services folder
    "AIAvatarIntegration.swift": "Services/",
    "APIClient.swift": "Services/",
    "MicroQuizOverlay.swift": "Services/",
    "GamificationOverlay.swift": "Services/",
    
    # Config -> Core/Configuration
    "APIConfig.swift": "Core/Configuration/",
    "AppConfig.swift": "Core/Configuration/",
    "CleanAppConfig.swift": "Core/Configuration/",
    "DevelopmentConfig.swift": "Core/Configuration/",
    "ProductionConfig.swift": "Core/Configuration/",
    
    # Network/API -> Core/Networking
    "APIError.swift": "Core/Networking/",
    "NetworkLayer.swift": "Core/Networking/",
    
    # ViewModels -> ViewModels folder
    "ClassroomViewModel.swift": "ViewModels/",
    
    # Coordinators -> Core/Coordinators
    "AvatarCompanionCoordinator.swift": "Core/Coordinators/",
    
    # Test/Debug files -> _Debug folder
    "BackendConnectivityTest.swift": "_Debug/",
    "CompilationSentinel.swift": "_Debug/",
    "TestClassroomView.swift": "_Debug/",
    
    # Utilities -> Utilities folder
    "DownloadStatus.swift": "Utilities/",
    "QuantumGateRiftButton.swift": "Components/",
}

def reorganize_files():
    """Move files according to the reorganization map"""
    moved = []
    errors = []
    
    for source_file, dest_folder in REORGANIZATION_MAP.items():
        source_path = os.path.join(LYOAPP_PATH, source_file)
        
        # Check if source exists
        if not os.path.exists(source_path):
            continue  # Already moved or doesn't exist
        
        # Create destination folder if it doesn't exist
        dest_folder_path = os.path.join(LYOAPP_PATH, dest_folder)
        os.makedirs(dest_folder_path, exist_ok=True)
        
        # Move file
        dest_path = os.path.join(dest_folder_path, source_file)
        
        try:
            shutil.move(source_path, dest_path)
            moved.append((source_file, dest_folder))
            print(f"✅ Moved: {source_file} → {dest_folder}")
        except Exception as e:
            errors.append((source_file, str(e)))
            print(f"❌ Error moving {source_file}: {e}")
    
    return moved, errors

def create_archive_folder():
    """Create _Archive folder for old code"""
    archive_path = os.path.join(LYOAPP_PATH, "_Archive")
    os.makedirs(archive_path, exist_ok=True)
    
    # Create README
    readme_path = os.path.join(archive_path, "README.md")
    with open(readme_path, 'w') as f:
        f.write("""# Archive Folder

This folder contains old/experimental code that's no longer active but kept for reference.

## Contents
- Test views and experimental UI
- Legacy services
- Old integration attempts
- Deprecated code

## Note
Files here are NOT compiled into the app.
""")
    
    print(f"✅ Created _Archive folder")

def main():
    print("🏗️  REORGANIZING ROOT FOLDER")
    print("=" * 80)
    
    # Create _Archive folder
    create_archive_folder()
    
    # Reorganize files
    moved, errors = reorganize_files()
    
    print("\n" + "=" * 80)
    print(f"📊 REORGANIZATION SUMMARY")
    print("=" * 80)
    print(f"  Files moved: {len(moved)}")
    print(f"  Errors: {len(errors)}")
    
    if errors:
        print("\n❌ Errors:")
        for file, error in errors:
            print(f"  • {file}: {error}")
    
    print(f"\n✅ Root folder reorganization complete!")
    print(f"   Files should now be in proper folders")

if __name__ == "__main__":
    main()
