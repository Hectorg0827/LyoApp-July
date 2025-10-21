#!/usr/bin/env python3
"""
Remove Avatar3D files from Xcode project build phase
Keeps files in project but excludes from compilation
"""

import re

def remove_avatar3d_from_build():
    pbxproj_path = "LyoApp.xcodeproj/project.pbxproj"
    
    # Read the project file
    with open(pbxproj_path, 'r') as f:
        content = f.read()
    
    # Find all Avatar3D file references
    avatar3d_patterns = [
        r'\t\t\t\t[A-F0-9]{24} /\* Avatar.*\.swift in Sources \*/,\n',
        r'\t\t\t\t[A-F0-9]{24} /\* Hair.*\.swift in Sources \*/,\n',
        r'\t\t\t\t[A-F0-9]{24} /\* Facial.*\.swift in Sources \*/,\n',
        r'\t\t\t\t[A-F0-9]{24} /\* Clothing.*\.swift in Sources \*/,\n',
        r'\t\t\t\t[A-F0-9]{24} /\* Voice.*\.swift in Sources \*/,\n',
    ]
    
    # Remove from PBXSourcesBuildPhase (compile sources)
    for pattern in avatar3d_patterns:
        content = re.sub(pattern, '', content)
    
    # Write back to file
    with open(pbxproj_path, 'w') as f:
        f.write(content)
    
    print("✅ Removed Avatar3D files from build sources")
    print("   Files remain in project but won't be compiled")
    print("   This allows the old avatar system to work without errors")

if __name__ == "__main__":
    remove_avatar3d_from_build()
