#!/usr/bin/env python3
"""
Add stub files to Xcode build target
"""
import re
import uuid

def generate_uuid():
    """Generate a 24-character hex UUID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

def add_files_to_xcode_project(project_path):
    """Add APIClientStub.swift and MissingTypesStubs.swift to Xcode project"""

    with open(project_path, 'r') as f:
        content = f.read()

    # Generate UUIDs for the new files
    api_stub_file_ref_uuid = generate_uuid()
    api_stub_build_file_uuid = generate_uuid()
    missing_types_file_ref_uuid = generate_uuid()
    missing_types_build_file_uuid = generate_uuid()

    print(f"Generated UUIDs:")
    print(f"  APIClientStub file ref: {api_stub_file_ref_uuid}")
    print(f"  APIClientStub build file: {api_stub_build_file_uuid}")
    print(f"  MissingTypesStubs file ref: {missing_types_file_ref_uuid}")
    print(f"  MissingTypesStubs build file: {missing_types_build_file_uuid}")

    # Check if files already exist in project
    if 'APIClientStub.swift' in content and 'MissingTypesStubs.swift' in content:
        print("\nFiles already exist in project file!")

        # Find their UUIDs
        api_match = re.search(r'([A-F0-9]{24}) /\* APIClientStub\.swift in Sources \*/', content)
        missing_match = re.search(r'([A-F0-9]{24}) /\* MissingTypesStubs\.swift in Sources \*/', content)

        if api_match:
            print(f"  APIClientStub build UUID: {api_match.group(1)}")
        if missing_match:
            print(f"  MissingTypesStubs build UUID: {missing_match.group(1)}")

        return

    # 1. Add PBXBuildFile entries for both files
    build_file_section_match = re.search(r'(/\* Begin PBXBuildFile section \*/\n)', content)
    if build_file_section_match:
        pos = build_file_section_match.end()
        new_build_files = f"\t\t{api_stub_build_file_uuid} /* APIClientStub.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {api_stub_file_ref_uuid} /* APIClientStub.swift */; }};\n"
        new_build_files += f"\t\t{missing_types_build_file_uuid} /* MissingTypesStubs.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {missing_types_file_ref_uuid} /* MissingTypesStubs.swift */; }};\n"
        content = content[:pos] + new_build_files + content[pos:]
        print("\n✓ Added PBXBuildFile entries")

    # 2. Add PBXFileReference entries for both files
    file_ref_section_match = re.search(r'(/\* Begin PBXFileReference section \*/\n)', content)
    if file_ref_section_match:
        pos = file_ref_section_match.end()
        new_file_refs = f"\t\t{api_stub_file_ref_uuid} /* APIClientStub.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = APIClientStub.swift; sourceTree = \"<group>\"; }};\n"
        new_file_refs += f"\t\t{missing_types_file_ref_uuid} /* MissingTypesStubs.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MissingTypesStubs.swift; sourceTree = \"<group>\"; }};\n"
        content = content[:pos] + new_file_refs + content[pos:]
        print("✓ Added PBXFileReference entries")

    # 3. Add to PBXSourcesBuildPhase (the files array)
    sources_phase_match = re.search(r'(/* Begin PBXSourcesBuildPhase section */.*?files = \()(.*?)(\);)', content, re.DOTALL)
    if sources_phase_match:
        files_content = sources_phase_match.group(2)
        new_entries = f"\n\t\t\t\t{api_stub_build_file_uuid} /* APIClientStub.swift in Sources */,"
        new_entries += f"\n\t\t\t\t{missing_types_build_file_uuid} /* MissingTypesStubs.swift in Sources */,"
        updated_files = files_content + new_entries
        content = content[:sources_phase_match.start(2)] + updated_files + content[sources_phase_match.end(2):]
        print("✓ Added to PBXSourcesBuildPhase")

    # 4. Add to appropriate groups in PBXGroup section
    # Add APIClientStub to Core/Networking group
    networking_group_match = re.search(r'(E8[A-F0-9]{22} /\* Networking \*/ = \{[^}]*children = \()(.*?)(\);)', content, re.DOTALL)
    if networking_group_match:
        children_content = networking_group_match.group(2)
        new_child = f"\n\t\t\t\t{api_stub_file_ref_uuid} /* APIClientStub.swift */,"
        updated_children = children_content + new_child
        content = content[:networking_group_match.start(2)] + updated_children + content[networking_group_match.end(2):]
        print("✓ Added APIClientStub.swift to Networking group")

    # Add MissingTypesStubs to Stubs group (or create it if it doesn't exist)
    stubs_group_match = re.search(r'([A-F0-9]{24}) /\* Stubs \*/ = \{[^}]*children = \()(.*?)(\);)', content, re.DOTALL)
    if stubs_group_match:
        children_content = stubs_group_match.group(2)
        new_child = f"\n\t\t\t\t{missing_types_file_ref_uuid} /* MissingTypesStubs.swift */,"
        updated_children = children_content + new_child
        content = content[:stubs_group_match.start(2)] + updated_children + content[stubs_group_match.end(2):]
        print("✓ Added MissingTypesStubs.swift to Stubs group")
    else:
        # If Stubs group doesn't exist, add to LyoApp group
        lyoapp_group_match = re.search(r'([A-F0-9]{24}) /\* LyoApp \*/ = \{[^}]*children = \()(.*?)(\);)', content, re.DOTALL)
        if lyoapp_group_match:
            children_content = lyoapp_group_match.group(2)
            new_child = f"\n\t\t\t\t{missing_types_file_ref_uuid} /* MissingTypesStubs.swift */,"
            updated_children = children_content + new_child
            content = content[:lyoapp_group_match.start(2)] + updated_children + content[lyoapp_group_match.end(2):]
            print("✓ Added MissingTypesStubs.swift to LyoApp group")

    # Write back to file
    with open(project_path, 'w') as f:
        f.write(content)

    print("\n✓ Successfully added both stub files to Xcode project!")
    print(f"  - APIClientStub.swift (Core/Networking)")
    print(f"  - MissingTypesStubs.swift (Stubs)")

if __name__ == "__main__":
    project_path = "/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj/project.pbxproj"
    add_files_to_xcode_project(project_path)
