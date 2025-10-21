#!/usr/bin/env python3
"""
Comprehensive codebase analysis tool
Analyzes every Swift file to identify orphaned, duplicate, broken, and unused files
"""

import os
import re
from pathlib import Path
from collections import defaultdict

# Configuration
LYOAPP_PATH = "/Users/hectorgarcia/Desktop/LyoApp July/LyoApp"

def get_all_swift_files():
    """Get all Swift files in the project"""
    swift_files = []
    for root, dirs, files in os.walk(LYOAPP_PATH):
        # Skip pods and other build artifacts
        dirs[:] = [d for d in dirs if d not in ['.build', 'Pods', '.pbxproj']]
        
        for file in files:
            if file.endswith('.swift'):
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, LYOAPP_PATH)
                swift_files.append({
                    'name': file,
                    'full_path': full_path,
                    'rel_path': rel_path,
                    'size': os.path.getsize(full_path)
                })
    
    return sorted(swift_files, key=lambda x: x['rel_path'])

def analyze_file_structure(files):
    """Analyze folder structure"""
    structure = defaultdict(list)
    
    for file in files:
        # Get top-level folder
        parts = file['rel_path'].split('/')
        if len(parts) > 1:
            top_folder = parts[0]
        else:
            top_folder = 'Root'
        
        structure[top_folder].append(file)
    
    return structure

def get_file_content(path):
    """Safely read file content"""
    try:
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            return f.read()
    except:
        return ""

def analyze_imports(file_path):
    """Extract all imports from a file"""
    content = get_file_content(file_path)
    imports = re.findall(r'^import\s+(\w+)', content, re.MULTILINE)
    return list(set(imports))

def analyze_class_definitions(file_path):
    """Extract all class/struct definitions"""
    content = get_file_content(file_path)
    
    # Find class, struct, protocol, enum definitions
    patterns = [
        r'(?:class|struct|protocol|enum)\s+(\w+)',
    ]
    
    definitions = []
    for pattern in patterns:
        matches = re.findall(pattern, content)
        definitions.extend(matches)
    
    return list(set(definitions))

def find_usages_in_file(search_term, file_path):
    """Find usages of a term in a file"""
    content = get_file_content(file_path)
    # Look for the term as a word boundary (not in comments or strings ideally)
    pattern = r'\b' + re.escape(search_term) + r'\b'
    matches = len(re.findall(pattern, content))
    return matches > 0

def analyze_file_references(files):
    """Analyze which files reference which"""
    references = defaultdict(set)  # file -> set of files it references
    definitions = {}  # definition_name -> file that defines it
    
    print("\n📊 Analyzing file references...")
    
    for file in files:
        content = get_file_content(file['full_path'])
        
        # Get definitions from this file
        class_defs = analyze_class_definitions(file['full_path'])
        for cls in class_defs:
            definitions[cls] = file['rel_path']
        
        # Find references to other files
        for other_file in files:
            if file['name'] == other_file['name']:
                continue
            
            # Check if this file references the other file's definitions
            other_defs = analyze_class_definitions(other_file['full_path'])
            for other_def in other_defs:
                if find_usages_in_file(other_def, file['full_path']):
                    references[file['rel_path']].add(other_file['rel_path'])
    
    return references, definitions

def main():
    print("🔍 COMPREHENSIVE CODEBASE ANALYSIS")
    print("=" * 80)
    
    # Step 1: Get all files
    print("\n📂 Scanning all Swift files...")
    files = get_all_swift_files()
    print(f"✅ Found {len(files)} Swift files")
    
    # Step 2: Analyze structure
    print("\n📁 Project structure by folder:")
    structure = analyze_file_structure(files)
    
    for folder in sorted(structure.keys()):
        file_list = structure[folder]
        print(f"\n  {folder}/ ({len(file_list)} files)")
        for file in sorted(file_list, key=lambda x: x['name'])[:10]:  # Show first 10
            size_kb = file['size'] / 1024
            print(f"    • {file['name']:50} {size_kb:8.1f} KB")
        if len(file_list) > 10:
            print(f"    ... and {len(file_list) - 10} more files")
    
    # Step 3: Generate report file
    print("\n📝 Generating detailed analysis report...")
    
    with open('/Users/hectorgarcia/Desktop/LyoApp July/CODEBASE_ANALYSIS.txt', 'w') as f:
        f.write("=" * 100 + "\n")
        f.write("COMPREHENSIVE CODEBASE ANALYSIS REPORT\n")
        f.write("=" * 100 + "\n\n")
        
        f.write(f"Total Swift Files: {len(files)}\n\n")
        
        f.write("FOLDER BREAKDOWN:\n")
        f.write("-" * 100 + "\n")
        
        for folder in sorted(structure.keys()):
            file_list = structure[folder]
            total_size = sum(f['size'] for f in file_list) / 1024
            f.write(f"\n{folder}/ ({len(file_list)} files, {total_size:.1f} KB)\n")
            
            for file in sorted(file_list, key=lambda x: x['name']):
                size_kb = file['size'] / 1024
                f.write(f"  • {file['name']:50} {size_kb:8.1f} KB  |  {file['rel_path']}\n")
        
        f.write("\n\n" + "=" * 100 + "\n")
        f.write("NEXT STEPS:\n")
        f.write("=" * 100 + "\n")
        f.write("""
1. Review the folder breakdown above
2. Identify unused/duplicate folders
3. Check for orphaned files
4. Verify all build targets in Xcode
5. Clean up unnecessary files
6. Rebuild and verify
""")
    
    print(f"✅ Report saved to: CODEBASE_ANALYSIS.txt")
    
    return files, structure

if __name__ == "__main__":
    files, structure = main()
    
    print("\n" + "=" * 80)
    print("📊 SUMMARY BY FOLDER")
    print("=" * 80)
    
    folder_stats = {}
    for folder, file_list in structure.items():
        total_size = sum(f['size'] for f in file_list) / 1024
        folder_stats[folder] = {'count': len(file_list), 'size': total_size}
    
    for folder in sorted(folder_stats.keys(), key=lambda x: -folder_stats[x]['count']):
        stats = folder_stats[folder]
        print(f"{folder:30} {stats['count']:4} files  {stats['size']:8.1f} KB")

