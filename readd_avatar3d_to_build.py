#!/usr/bin/env python3
"""
Re-add Avatar3D files to Xcode build phase
"""

import re

def readd_avatar3d_to_build():
    pbxproj_path = "LyoApp.xcodeproj/project.pbxproj"
    
    # Read the project file
    with open(pbxproj_path, 'r') as f:
        content = f.read()
    
    # Find UUIDs for all Avatar3D files
    avatar3d_files = [
        'AvatarAnimationSystem.swift',
        'Avatar3DModel.swift',
        'Avatar3DPersistence.swift',
        'Avatar3DRenderer.swift',
        'Avatar3DCreatorView.swift',
        'Avatar3DMigrationView.swift',
        'ClothingCustomizationViews.swift',
        'FacialFeatureViews.swift',
        'HairCustomizationViews.swift',
        'VoiceSelectionViews.swift'
    ]
    
    file_mappings = {}
    
    # Extract UUIDs for build files
    for filename in avatar3d_files:
        pattern = rf'([A-F0-9]{{24}}) /\* {re.escape(filename)} in Sources \*/ = {{isa = PBXBuildFile'
        match = re.search(pattern, content)
        if match:
            file_mappings[filename] = match.group(1)
            print(f"Found {filename}: {match.group(1)}")
    
    # Find the PBXSourcesBuildPhase section
    sources_build_phase = re.search(r'(/\* Sources \*/.*?isa = PBXSourcesBuildPhase;.*?files = \()', content, re.DOTALL)
    if sources_build_phase:
        insert_pos = sources_build_phase.end()
        entries_to_add = "\n"
        
        for filename, uuid in file_mappings.items():
            # Check if already in build phase
            check_pattern = rf'{uuid} /\* {re.escape(filename)} in Sources \*/,'
            if not re.search(check_pattern, content):
                entries_to_add += f"\t\t\t\t{uuid} /* {filename} in Sources */,\n"
        
        if entries_to_add.strip():
            content = content[:insert_pos] + entries_to_add + content[insert_pos:]
    
    # Write back
    with open(pbxproj_path, 'w') as f:
        f.write(content)
    
    print(f"\n✅ Added {len(file_mappings)} Avatar3D files back to build sources")

if __name__ == "__main__":
    readd_avatar3d_to_build()
