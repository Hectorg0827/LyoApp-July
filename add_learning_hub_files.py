#!/usr/bin/env python3
"""
Add Learning Hub files to Xcode project
"""
import re
import uuid
import sys

def generate_uuid():
    """Generate a 24-character uppercase UUID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

def add_files_to_xcode():
    # Files to add with their relative paths
    files_to_add = [
        {
            'path': 'LyoApp/LearningHub/Views/LearningHubLandingView.swift',
            'name': 'LearningHubLandingView.swift',
            'group': 'Views'
        },
        {
            'path': 'LyoApp/LearningHub/ViewModels/LearningChatViewModel.swift',
            'name': 'LearningChatViewModel.swift',
            'group': 'ViewModels'
        },
        {
            'path': 'LyoApp/LearningHub/Views/Components/CourseJourneyPreviewCard.swift',
            'name': 'CourseJourneyPreviewCard.swift',
            'group': 'Components'
        },
        {
            'path': 'LyoApp/Services/VoiceRecognitionService.swift',
            'name': 'VoiceRecognitionService.swift',
            'group': 'Services'
        },
        {
            'path': 'LyoApp/Services/LearningHubAnalytics.swift',
            'name': 'LearningHubAnalytics.swift',
            'group': 'Services'
        },
    ]
    
    # Read project file
    project_file = 'LyoApp.xcodeproj/project.pbxproj'
    with open(project_file, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # Find the PBXBuildFile section
    build_file_section_match = re.search(
        r'(/\* Begin PBXBuildFile section \*/)(.*?)(/\* End PBXBuildFile section \*/)',
        content, re.DOTALL
    )
    
    # Find the PBXFileReference section
    file_ref_section_match = re.search(
        r'(/\* Begin PBXFileReference section \*/)(.*?)(/\* End PBXFileReference section \*/)',
        content, re.DOTALL
    )
    
    # Find the PBXSourcesBuildPhase section
    sources_build_phase_match = re.search(
        r'(/\* Begin PBXSourcesBuildPhase section \*/.*?files = \()(.*?)(\);)',
        content, re.DOTALL
    )
    
    if not all([build_file_section_match, file_ref_section_match, sources_build_phase_match]):
        print("❌ Could not find required sections in project file")
        return False
    
    files_added = []
    
    for file_info in files_to_add:
        filename = file_info['name']
        filepath = file_info['path']
        
        # Check if already exists
        if filename in content:
            print(f"⏭️  {filename} already in project")
            continue
        
        # Generate UUIDs
        file_ref_uuid = generate_uuid()
        build_file_uuid = generate_uuid()
        
        # Create PBXBuildFile entry
        build_file_entry = f"\t\t{build_file_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {filename} */; }};\n"
        
        # Create PBXFileReference entry
        file_ref_entry = f"\t\t{file_ref_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};\n"
        
        # Create PBXSourcesBuildPhase entry
        sources_entry = f"\t\t\t\t{build_file_uuid} /* {filename} in Sources */,\n"
        
        # Insert entries
        # Add to PBXBuildFile section (at the end before closing comment)
        content = content.replace(
            build_file_section_match.group(3),
            build_file_entry + build_file_section_match.group(3)
        )
        
        # Add to PBXFileReference section (at the end before closing comment)
        content = content.replace(
            file_ref_section_match.group(3),
            file_ref_entry + file_ref_section_match.group(3)
        )
        
        # Add to PBXSourcesBuildPhase files array
        # Find the sources phase again (content has changed)
        sources_build_phase_match = re.search(
            r'(/\* Begin PBXSourcesBuildPhase section \*/.*?files = \()(.*?)(\);)',
            content, re.DOTALL
        )
        if sources_build_phase_match:
            content = content.replace(
                sources_build_phase_match.group(3),
                sources_entry + sources_build_phase_match.group(3)
            )
        
        files_added.append(filename)
        print(f"✅ Added {filename}")
    
    if files_added:
        # Write back to file
        with open(project_file, 'w') as f:
            f.write(content)
        
        print(f"\n🎉 Successfully added {len(files_added)} file(s) to Xcode project!")
        print("\n📋 Files added:")
        for f in files_added:
            print(f"   ✓ {f}")
        return True
    else:
        print("\n✅ All files already in project, no changes needed")
        return True

if __name__ == "__main__":
    try:
        success = add_files_to_xcode()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
