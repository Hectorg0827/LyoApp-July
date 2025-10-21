#!/usr/bin/env python3
import re

with open('/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Find the files section in PBXSourcesBuildPhase
match = re.search(r'files = \((.*?)\);', content, re.DOTALL)
if match:
    files_section = match.group(1)
    
    # Extract all build file IDs
    pattern = r'([A-F0-9]{24}) /\* ([^*]+) in Sources \*/'
    matches = re.findall(pattern, files_section)
    
    print(f"Total entries: {len(matches)}")
    
    # Find duplicates
    seen_files = {}
    duplicates = []
    
    for build_id, filename in matches:
        if filename in seen_files:
            duplicates.append((filename, build_id, seen_files[filename]))
            print(f"DUP: {filename}")
            print(f"  - First: {seen_files[filename]}")
            print(f"  - Second: {build_id}")
        else:
            seen_files[filename] = build_id
    
    print(f"\nFound {len(duplicates)} duplicate files")
