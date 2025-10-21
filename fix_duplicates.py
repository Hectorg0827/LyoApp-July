#!/usr/bin/env python3
import re
import sys

# Read the project file
with open('/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Extract the files section (buildPhase Sources section)
# We're looking for the pattern that starts with files = ( and ends with );
# This contains all the file references that get compiled

# Find the main "files" array in the Sources build phase
# Pattern: look for the PBXSourcesBuildPhase section with files = (
pattern = r'(isa = PBXSourcesBuildPhase;.*?files = \()(.*?)(\);)'
match = re.search(pattern, content, re.DOTALL)

if match:
    prefix = match.group(1)
    files_content = match.group(2)
    suffix = match.group(3)
    
    # Extract all file references from the files section
    # Format is typically: buildFileID in Sources,
    file_refs = re.findall(r'([A-F0-9]{24}) in Sources', files_content)
    
    print(f"Total file references found: {len(file_refs)}")
    print(f"Unique references: {len(set(file_refs))}")
    
    # Keep track of which ones we've seen
    seen = set()
    duplicates_to_remove = []
    
    for ref in file_refs:
        if ref in seen:
            duplicates_to_remove.append(ref)
        else:
            seen.add(ref)
    
    print(f"Duplicates to remove: {len(duplicates_to_remove)}")
    
    if duplicates_to_remove:
        # Create a new files section with duplicates removed
        new_files = files_content
        
        # For each duplicate, remove the LAST occurrence
        for dup_ref in duplicates_to_remove:
            # Find and remove the last occurrence
            pattern_to_remove = rf'\t\t\t\t{dup_ref} in Sources,\n'
            matches = list(re.finditer(pattern_to_remove, new_files))
            if matches:
                # Remove the last match
                last_match = matches[-1]
                new_files = new_files[:last_match.start()] + new_files[last_match.end():]
        
        # Reconstruct the full content
        new_content = content[:match.start()] + prefix + new_files + suffix + content[match.end():]
        
        # Write back
        with open('/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj/project.pbxproj', 'w') as f:
            f.write(new_content)
        
        print(f"✅ Removed {len(duplicates_to_remove)} duplicate references")
    else:
        print("No duplicates found in files section")
else:
    print("Could not find files section in project.pbxproj")

