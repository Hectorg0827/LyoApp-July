#!/usr/bin/env python3
import re
import uuid

def generate_uuid():
    return uuid.uuid4().hex[:24].upper()

project_path = "/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj/project.pbxproj"

with open(project_path, 'r') as f:
    content = f.read()

# Check if already added
if 'APIClientStub.swift' in content:
    print("APIClientStub.swift already in project!")
    exit(0)

# Generate UUIDs
api_file_ref = generate_uuid()
api_build_file = generate_uuid()
missing_file_ref = generate_uuid()
missing_build_file = generate_uuid()

print(f"APIClientStub file ref: {api_file_ref}")
print(f"APIClientStub build file: {api_build_file}")
print(f"MissingTypesStubs file ref: {missing_file_ref}")
print(f"MissingTypesStubs build file: {missing_build_file}")

# 1. Add PBXBuildFile entries
build_section_start = content.find('/* Begin PBXBuildFile section */')
build_section_newline = content.find('\n', build_section_start) + 1
new_build_entries = f"\t\t{api_build_file} /* APIClientStub.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {api_file_ref} /* APIClientStub.swift */; }};\n"
new_build_entries += f"\t\t{missing_build_file} /* MissingTypesStubs.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {missing_file_ref} /* MissingTypesStubs.swift */; }};\n"
content = content[:build_section_newline] + new_build_entries + content[build_section_newline:]

# 2. Add PBXFileReference entries
file_ref_section_start = content.find('/* Begin PBXFileReference section */')
file_ref_newline = content.find('\n', file_ref_section_start) + 1
new_file_refs = f"\t\t{api_file_ref} /* APIClientStub.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = APIClientStub.swift; sourceTree = \"<group>\"; }};\n"
new_file_refs += f"\t\t{missing_file_ref} /* MissingTypesStubs.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MissingTypesStubs.swift; sourceTree = \"<group>\"; }};\n"
content = content[:file_ref_newline] + new_file_refs + content[file_ref_newline:]

# 3. Add to PBXSourcesBuildPhase
sources_phase_start = content.find('/* Begin PBXSourcesBuildPhase section */')
files_start = content.find('files = (', sources_phase_start)
files_end = content.find(');', files_start)
files_section = content[files_start:files_end]

new_source_entries = f"\n\t\t\t\t{api_build_file} /* APIClientStub.swift in Sources */,"
new_source_entries += f"\n\t\t\t\t{missing_build_file} /* MissingTypesStubs.swift in Sources */,"
content = content[:files_end] + new_source_entries + content[files_end:]

# Write back
with open(project_path, 'w') as f:
    f.write(content)

print("✓ Successfully added stub files to Xcode project!")
