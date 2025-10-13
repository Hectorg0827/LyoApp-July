#!/usr/bin/env python3
"""
Script to add Avatar3D files to Xcode build phase
"""
import re
import sys

def add_files_to_build_phase(pbxproj_path):
    """Add Avatar3D files to PBXSourcesBuildPhase"""
    
    # Read the project file
    with open(pbxproj_path, 'r') as f:
        content = f.read()
    
    # Avatar3D files to add (these should already be in PBXBuildFile section)
    avatar3d_files = [
        'Avatar3DModel.swift',
        'Avatar3DRenderer.swift',
        'Avatar3DCreatorView.swift',
        'FacialFeatureViews.swift',
        'HairCustomizationViews.swift',
        'ClothingCustomizationViews.swift',
        'VoiceSelectionViews.swift',
        'Avatar3DMigrationView.swift',
        'AvatarAnimationSystem.swift',
        'Avatar3DPersistence.swift'
    ]
    
    # Find the build file references for Avatar3D files
    build_file_refs = []
    for filename in avatar3d_files:
        # Find the PBXBuildFile entry for this file
        pattern = rf'([A-F0-9]+) /\* {re.escape(filename)} in Sources \*/'
        match = re.search(pattern, content)
        if match:
            build_file_refs.append(match.group(1))
            print(f"✅ Found build reference for {filename}: {match.group(1)}")
        else:
            print(f"⚠️  Could not find build reference for {filename}")
    
    if not build_file_refs:
        print("❌ No Avatar3D build file references found!")
        return False
    
    # Find the PBXSourcesBuildPhase section
    sources_phase_pattern = r'(/\* Sources \*/.*?isa = PBXSourcesBuildPhase;.*?files = \()(.*?)(\);)'
    match = re.search(sources_phase_pattern, content, re.DOTALL)
    
    if not match:
        print("❌ Could not find PBXSourcesBuildPhase section!")
        return False
    
    before = match.group(1)
    files_section = match.group(2)
    after = match.group(3)
    
    # Check which files are already in the build phase
    files_to_add = []
    for ref in build_file_refs:
        if ref not in files_section:
            files_to_add.append(ref)
        else:
            print(f"ℹ️  File reference {ref} already in build phase")
    
    if not files_to_add:
        print("✅ All Avatar3D files already in build phase!")
        return True
    
    # Add the missing files
    new_entries = []
    for ref in files_to_add:
        new_entries.append(f"\t\t\t\t{ref} /* Avatar3D file */,")
    
    # Insert the new entries at the end of the files list
    new_files_section = files_section.rstrip()
    if not new_files_section.endswith(','):
        new_files_section += ','
    new_files_section += '\n' + '\n'.join(new_entries) + '\n\t\t\t'
    
    # Reconstruct the content
    new_content = content[:match.start()] + before + new_files_section + after + content[match.end():]
    
    # Write back
    with open(pbxproj_path, 'w') as f:
        f.write(new_content)
    
    print(f"✅ Added {len(files_to_add)} Avatar3D files to build phase")
    return True

if __name__ == '__main__':
    pbxproj_path = '/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj/project.pbxproj'
    
    print("Adding Avatar3D files to Xcode build phase...")
    success = add_files_to_build_phase(pbxproj_path)
    
    if success:
        print("\n✅ Avatar3D files successfully added to build!")
        print("Next: Build the project to verify compilation")
    else:
        print("\n❌ Failed to add Avatar3D files to build")
        sys.exit(1)
