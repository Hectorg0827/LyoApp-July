#!/usr/bin/env python3
"""
Add core avatar files back to build phase
"""

import re

def add_core_files_to_build():
    pbxproj_path = "LyoApp.xcodeproj/project.pbxproj"
    
    # Read the project file
    with open(pbxproj_path, 'r') as f:
        content = f.read()
    
    # Find the UUID mappings for our core files
    file_mappings = {
        'AvatarStore.swift': None,
        'VoiceRecognizer.swift': None,
        'VoiceActivationService.swift': None,
        'AvatarModels.swift': None
    }
    
    # Extract UUIDs for build files (these link fileRef to build phase)
    for filename in file_mappings.keys():
        pattern = rf'([A-F0-9]{{24}}) /\* {re.escape(filename)} in Sources \*/ = {{isa = PBXBuildFile; fileRef = ([A-F0-9]{{24}})'
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
            if uuid:
                entries_to_add += f"\t\t\t\t{uuid} /* {filename} in Sources */,\n"
        
        content = content[:insert_pos] + entries_to_add + content[insert_pos:]
    
    # Write back
    with open(pbxproj_path, 'w') as f:
        f.write(content)
    
    print("\n✅ Added core avatar files back to build sources:")
    for filename in file_mappings.keys():
        print(f"   - {filename}")

if __name__ == "__main__":
    add_core_files_to_build()
