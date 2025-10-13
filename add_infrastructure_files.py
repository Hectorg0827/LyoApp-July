#!/usr/bin/env python3
"""
Add missing infrastructure files to Xcode project
"""

import uuid
import re

def generate_uuid():
    """Generate a unique 24-character hex ID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

def add_files_to_pbxproj():
    pbxproj_path = "LyoApp.xcodeproj/project.pbxproj"
    
    # Read the project file
    with open(pbxproj_path, 'r') as f:
        content = f.read()
    
    # Infrastructure files to add (only files that might not be in build)
    files = [
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
    
    # Check which files are NOT already in the build
    files_to_add = []
    files_already_present = []
    
    for file_path in files:
        file_name = file_path.split('/')[-1]
        # Check if file is already referenced
        if file_name not in content:
            files_to_add.append(file_path)
        else:
            # Check if it's in the build phase
            if re.search(rf'{re.escape(file_name)} in Sources', content):
                files_already_present.append(file_name)
            else:
                files_to_add.append(file_path)
    
    if not files_to_add:
        print("✅ All infrastructure files are already in the build!")
        print(f"   {len(files_already_present)} files verified in build")
        return
    
    print(f"🔧 Adding {len(files_to_add)} missing infrastructure files...")
    
    # Generate UUIDs for each file (fileRef and buildFile)
    file_refs = []
    build_files = []
    
    for file_path in files_to_add:
        file_name = file_path.split('/')[-1]
        fileref_uuid = generate_uuid()
        buildfile_uuid = generate_uuid()
        
        file_refs.append({
            'uuid': fileref_uuid,
            'path': file_path,
            'name': file_name
        })
        
        build_files.append({
            'uuid': buildfile_uuid,
            'fileref': fileref_uuid,
            'name': file_name
        })
    
    # 1. Add PBXFileReference entries
    pbxfilereference_section = re.search(r'/\* Begin PBXFileReference section \*/', content)
    if pbxfilereference_section:
        insert_pos = pbxfilereference_section.end()
        file_ref_entries = "\n"
        for ref in file_refs:
            file_ref_entries += f"\t\t{ref['uuid']} /* {ref['name']} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {ref['name']}; sourceTree = \"<group>\"; }};\n"
        
        content = content[:insert_pos] + file_ref_entries + content[insert_pos:]
    
    # 2. Add PBXBuildFile entries
    pbxbuildfile_section = re.search(r'/\* Begin PBXBuildFile section \*/', content)
    if pbxbuildfile_section:
        insert_pos = pbxbuildfile_section.end()
        build_file_entries = "\n"
        for bf in build_files:
            build_file_entries += f"\t\t{bf['uuid']} /* {bf['name']} in Sources */ = {{isa = PBXBuildFile; fileRef = {bf['fileref']} /* {bf['name']} */; }};\n"
        
        content = content[:insert_pos] + build_file_entries + content[insert_pos:]
    
    # 3. Add to PBXSourcesBuildPhase (compile sources)
    sources_build_phase = re.search(r'(/\* Sources \*/.*?isa = PBXSourcesBuildPhase;.*?files = \()', content, re.DOTALL)
    if sources_build_phase:
        insert_pos = sources_build_phase.end()
        source_entries = "\n"
        for bf in build_files:
            source_entries += f"\t\t\t\t{bf['uuid']} /* {bf['name']} in Sources */,\n"
        
        content = content[:insert_pos] + source_entries + content[insert_pos:]
    
    # Write back to file
    with open(pbxproj_path, 'w') as f:
        f.write(content)
    
    print("✅ Successfully added infrastructure files to Xcode project!")
    print(f"   Added {len(files_to_add)} Swift files to build")
    print(f"   Already in build: {len(files_already_present)} files")
    print("\n📋 Files added:")
    for f in files_to_add:
        print(f"   ✓ {f.split('/')[-1]}")
    print("\n🔨 Next: Build the project to verify")

if __name__ == "__main__":
    add_files_to_pbxproj()
