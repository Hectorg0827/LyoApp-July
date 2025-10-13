#!/usr/bin/env python3
"""
Add missing infrastructure files to Xcode build
"""

import sys
import os

# Add the parent directory to path to import xcode_helper
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from xcode_helper import XcodeProjectHelper

def main():
    project_path = "LyoApp.xcodeproj/project.pbxproj"
    
    # Files to add to build
    files_to_add = [
        "LyoApp/ContentView.swift",
        "LyoApp/Managers/AvatarStore.swift",
        "LyoApp/QuickAvatarSetupView.swift",
        "LyoApp/Core/Configuration/BackendConfig.swift",
        "LyoApp/APIConfig.swift",
        "LyoApp/AppState.swift",
        "LyoApp/Managers/SimplifiedAuthenticationManager.swift",
        "LyoApp/VoiceActivationService.swift",
        "LyoApp/UserDataManager.swift",
        "LyoApp/AuthenticationView.swift",
        "LyoApp/APIClient.swift",
        "LyoApp/APIError.swift",
        "LyoApp/SystemHealthResponse.swift",
    ]
    
    print("🔧 Adding missing infrastructure files to Xcode build...")
    print(f"📁 Project: {project_path}")
    print(f"📝 Files to add: {len(files_to_add)}")
    print()
    
    helper = XcodeProjectHelper(project_path)
    
    added_count = 0
    already_in_build = 0
    
    for file_path in files_to_add:
        print(f"Processing: {file_path}")
        
        # Check if file exists
        if not os.path.exists(file_path):
            print(f"  ⚠️  File not found, skipping")
            continue
        
        # Add to project
        success = helper.add_file_to_build(file_path)
        
        if success:
            added_count += 1
            print(f"  ✅ Added to build")
        else:
            already_in_build += 1
            print(f"  ℹ️  Already in build or failed to add")
    
    print()
    print("=" * 60)
    print(f"✅ Added {added_count} files to build")
    print(f"ℹ️  {already_in_build} files already in build")
    print(f"📊 Total processed: {len(files_to_add)}")
    print("=" * 60)
    print()
    print("🎉 Infrastructure files added successfully!")
    print("💡 Next step: Build the project")

if __name__ == "__main__":
    main()
