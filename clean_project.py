#!/usr/bin/env python3
import re

# Read the project file
with open('/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj/project.pbxproj', 'r') as f:
    lines = f.readlines()

# Track which build file IDs (the hex codes) we've seen in the files = ( ... ); section
in_sources_section = False
seen_build_ids = set()
duplicates_line_numbers = []

for i, line in enumerate(lines):
    if 'isa = PBXSourcesBuildPhase' in line:
        in_sources_section = True
        continue
    
    if in_sources_section and 'files = (' in line:
        # Start collecting
        continue
    
    if in_sources_section and line.strip() == ');':
        # End of section
        in_sources_section = False
        continue
    
    if in_sources_section:
        # Extract the build file ID (24-char hex code at the start)
        match = re.match(r'\s*([A-F0-9]{24})\s', line)
        if match:
            build_id = match.group(1)
            if build_id in seen_build_ids:
                duplicates_line_numbers.append(i)
                print(f"Line {i+1}: DUPLICATE - {build_id} {line.strip()[:70]}")
            else:
                seen_build_ids.add(build_id)
        elif '(null)' in line:
            duplicates_line_numbers.append(i)
            print(f"Line {i+1}: NULL ENTRY - {line.strip()[:70]}")

print(f"\nFound {len(duplicates_line_numbers)} duplicate/null lines to remove")

# Remove duplicates in reverse order so line numbers don't shift
for line_num in sorted(duplicates_line_numbers, reverse=True):
    del lines[line_num]

# Write back
with open('/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj/project.pbxproj', 'w') as f:
    f.writelines(lines)

print(f"✅ Removed {len(duplicates_line_numbers)} duplicate/null entries")
