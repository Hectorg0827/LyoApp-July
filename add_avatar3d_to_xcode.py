#!/usr/bin/env python3
"""
Add Avatar3D files to Xcode project
Modifies LyoApp.xcodeproj/project.pbxproj to include Avatar3D Swift files
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
    
    # Avatar3D files to add
    files = [
        "LyoApp/Avatar3D/Animation/AvatarAnimationSystem.swift",
        "LyoApp/Avatar3D/Models/Avatar3DModel.swift",
        "LyoApp/Avatar3D/Persistence/Avatar3DPersistence.swift",
        "LyoApp/Avatar3D/Rendering/Avatar3DRenderer.swift",
        "LyoApp/Avatar3D/Views/Avatar3DCreatorView.swift",
        "LyoApp/Avatar3D/Views/Avatar3DMigrationView.swift",
        "LyoApp/Avatar3D/Views/ClothingCustomizationViews.swift",
        "LyoApp/Avatar3D/Views/FacialFeatureViews.swift",
        "LyoApp/Avatar3D/Views/HairCustomizationViews.swift",
        "LyoApp/Avatar3D/Views/VoiceSelectionViews.swift",
    ]
    
    # Generate UUIDs for each file (fileRef and buildFile)
    file_refs = []
    build_files = []
    
    for file_path in files:
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
    
    # 4. Add Avatar3D group structure
    # Find the LyoApp group (main app group)
    lyoapp_group = re.search(r'([A-F0-9]{24}) /\* LyoApp \*/ = \{[^}]*?children = \([^)]*?\);', content)
    if lyoapp_group:
        group_uuid = lyoapp_group.group(1)
        children_section = re.search(rf'{group_uuid} /\* LyoApp \*/ = \{{[^}}]*?children = \((.*?)\);', content, re.DOTALL)
        
        if children_section:
            # Create UUIDs for Avatar3D folder structure
            avatar3d_group_uuid = generate_uuid()
            models_group_uuid = generate_uuid()
            rendering_group_uuid = generate_uuid()
            views_group_uuid = generate_uuid()
            animation_group_uuid = generate_uuid()
            persistence_group_uuid = generate_uuid()
            
            # Add Avatar3D to LyoApp's children
            children_content = children_section.group(1)
            if avatar3d_group_uuid not in children_content:
                # Insert at the beginning of children
                insert_pos = children_section.start(1)
                content = content[:insert_pos] + f"\n\t\t\t\t{avatar3d_group_uuid} /* Avatar3D */," + content[insert_pos:]
            
            # Add group definitions before /* End PBXGroup section */
            pbxgroup_end = re.search(r'/\* End PBXGroup section \*/', content)
            if pbxgroup_end:
                insert_pos = pbxgroup_end.start()
                
                # Avatar3D main group
                group_defs = f"""		{avatar3d_group_uuid} /* Avatar3D */ = {{
			isa = PBXGroup;
			children = (
				{models_group_uuid} /* Models */,
				{rendering_group_uuid} /* Rendering */,
				{views_group_uuid} /* Views */,
				{animation_group_uuid} /* Animation */,
				{persistence_group_uuid} /* Persistence */,
			);
			path = Avatar3D;
			sourceTree = "<group>";
		}};
		{models_group_uuid} /* Models */ = {{
			isa = PBXGroup;
			children = (
				{file_refs[1]['uuid']} /* Avatar3DModel.swift */,
			);
			path = Models;
			sourceTree = "<group>";
		}};
		{rendering_group_uuid} /* Rendering */ = {{
			isa = PBXGroup;
			children = (
				{file_refs[3]['uuid']} /* Avatar3DRenderer.swift */,
			);
			path = Rendering;
			sourceTree = "<group>";
		}};
		{views_group_uuid} /* Views */ = {{
			isa = PBXGroup;
			children = (
				{file_refs[4]['uuid']} /* Avatar3DCreatorView.swift */,
				{file_refs[5]['uuid']} /* Avatar3DMigrationView.swift */,
				{file_refs[6]['uuid']} /* ClothingCustomizationViews.swift */,
				{file_refs[7]['uuid']} /* FacialFeatureViews.swift */,
				{file_refs[8]['uuid']} /* HairCustomizationViews.swift */,
				{file_refs[9]['uuid']} /* VoiceSelectionViews.swift */,
			);
			path = Views;
			sourceTree = "<group>";
		}};
		{animation_group_uuid} /* Animation */ = {{
			isa = PBXGroup;
			children = (
				{file_refs[0]['uuid']} /* AvatarAnimationSystem.swift */,
			);
			path = Animation;
			sourceTree = "<group>";
		}};
		{persistence_group_uuid} /* Persistence */ = {{
			isa = PBXGroup;
			children = (
				{file_refs[2]['uuid']} /* Avatar3DPersistence.swift */,
			);
			path = Persistence;
			sourceTree = "<group>";
		}};
"""
                content = content[:insert_pos] + group_defs + content[insert_pos:]
    
    # Write back to file
    with open(pbxproj_path, 'w') as f:
        f.write(content)
    
    print("✅ Successfully added Avatar3D files to Xcode project!")
    print(f"   Added {len(files)} Swift files")
    print("   - Models: Avatar3DModel.swift")
    print("   - Rendering: Avatar3DRenderer.swift")
    print("   - Views: 6 view files")
    print("   - Animation: AvatarAnimationSystem.swift")
    print("   - Persistence: Avatar3DPersistence.swift")
    print("\n🔧 Next: Update LyoApp.swift to use Avatar3DCreatorView")

if __name__ == "__main__":
    add_files_to_pbxproj()
