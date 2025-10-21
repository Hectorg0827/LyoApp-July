#!/usr/bin/env python3
"""
Advanced codebase quality analysis
Find: duplicates, orphans, broken imports, unused files, dead code
"""

import os
import re
from pathlib import Path
from collections import defaultdict

LYOAPP_PATH = "/Users/hectorgarcia/Desktop/LyoApp July/LyoApp"

def get_all_swift_files():
    swift_files = []
    for root, dirs, files in os.walk(LYOAPP_PATH):
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

def get_file_content(path):
    try:
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            return f.read()
    except:
        return ""

def find_class_definitions(content):
    """Find all class/struct/protocol/enum names"""
    patterns = [
        r'(?:class|struct|protocol|enum)\s+(\w+)',
    ]
    defs = []
    for pattern in patterns:
        defs.extend(re.findall(pattern, content))
    return list(set(defs))

def find_imports(content):
    """Find all imports"""
    return re.findall(r'^import\s+(\w+)', content, re.MULTILINE)

def find_view_instantiations(content):
    """Find View() instantiations"""
    # Look for patterns like: SomeView(), SomeView{, NavigationLink("text", SomeView())
    patterns = [
        r'\b(\w+View)\(',
        r'\b(\w+ViewModel)\(',
        r'\b(\w+Manager)\(',
    ]
    insts = []
    for pattern in patterns:
        insts.extend(re.findall(pattern, content))
    return list(set(insts))

def analyze_dead_code():
    """Find unused/dead code files"""
    files = get_all_swift_files()
    
    print("\n" + "=" * 100)
    print("🔴 CRITICAL ISSUES FOUND")
    print("=" * 100)
    
    # Track all definitions and usages
    all_definitions = defaultdict(list)  # name -> list of (file, line_number)
    all_usages = defaultdict(int)  # name -> count of usages
    
    # First pass: collect all definitions
    for file in files:
        content = get_file_content(file['full_path'])
        defs = find_class_definitions(content)
        
        for defn in defs:
            all_definitions[defn].append(file['rel_path'])
    
    # Second pass: find usages
    for file in files:
        content = get_file_content(file['full_path'])
        
        # Find all words that look like they could be class names
        for defn in all_definitions.keys():
            if re.search(r'\b' + re.escape(defn) + r'\b', content):
                # Only count if it's not in the file where it's defined
                if file['rel_path'] not in all_definitions[defn]:
                    all_usages[defn] += 1
    
    # Find definitions with no usages outside their file
    unused_definitions = []
    for defn, files_with_def in all_definitions.items():
        usage_count = all_usages.get(defn, 0)
        if usage_count == 0 and len(files_with_def) == 1:
            unused_definitions.append({
                'name': defn,
                'file': files_with_def[0],
                'usages': 0
            })
    
    # Find duplicate definitions
    duplicates = []
    for defn, files_with_def in all_definitions.items():
        if len(files_with_def) > 1:
            duplicates.append({
                'name': defn,
                'files': files_with_def,
                'count': len(files_with_def)
            })
    
    # Find empty/stub files
    empty_files = []
    for file in files:
        content = get_file_content(file['full_path']).strip()
        if len(content) < 50:  # Less than 50 chars
            empty_files.append({
                'file': file['rel_path'],
                'size': file['size']
            })
    
    # Report findings
    print("\n1️⃣  DUPLICATE CLASS/STRUCT DEFINITIONS:")
    print("-" * 100)
    if duplicates:
        for dup in sorted(duplicates, key=lambda x: -x['count'])[:20]:
            print(f"\n  ⚠️  {dup['name']} (defined {dup['count']} times)")
            for f in dup['files']:
                print(f"      • {f}")
    else:
        print("  ✅ No duplicate definitions found")
    
    print("\n\n2️⃣  POTENTIALLY UNUSED FILES (no external references):")
    print("-" * 100)
    if unused_definitions:
        for unused in sorted(unused_definitions, key=lambda x: x['name'])[:30]:
            print(f"  • {unused['file']:60} - {unused['name']}")
    else:
        print("  ✅ No unused definitions found")
    
    print("\n\n3️⃣  EMPTY OR STUB FILES (<50 bytes):")
    print("-" * 100)
    if empty_files:
        for empty in sorted(empty_files, key=lambda x: x['file']):
            print(f"  • {empty['file']:60} - {empty['size']} bytes")
    else:
        print("  ✅ No empty files found")
    
    # Look for problematic patterns
    print("\n\n4️⃣  PROBLEMATIC FILES TO REVIEW:")
    print("-" * 100)
    
    problematic = []
    for file in files:
        rel_path = file['rel_path']
        content = get_file_content(file['full_path'])
        
        issues = []
        
        # Check for orphaned View files (Views that aren't instantiated)
        if 'View' in file['name'] and not file['name'].startswith('.'):
            # Check if it's instantiated anywhere
            view_name = file['name'].replace('.swift', '')
            is_used = False
            for other_file in files:
                if other_file['rel_path'] == rel_path:
                    continue
                other_content = get_file_content(other_file['full_path'])
                if re.search(r'\b' + re.escape(view_name) + r'\b', other_content):
                    is_used = True
                    break
            
            if not is_used and view_name not in ['ContentView', 'LyoApp']:
                issues.append(f"Unused view: {view_name}")
        
        # Check for files that import but don't use
        imports = find_imports(content)
        if imports:
            # This is complex to analyze properly, skip for now
            pass
        
        if issues:
            problematic.append({
                'file': rel_path,
                'issues': issues
            })
    
    if problematic:
        for prob in sorted(problematic, key=lambda x: x['file'])[:20]:
            print(f"\n  • {prob['file']}")
            for issue in prob['issues']:
                print(f"      - {issue}")
    else:
        print("  ✅ No obvious problematic patterns found")
    
    print("\n\n5️⃣  FOLDER REDUNDANCY CHECK:")
    print("-" * 100)
    
    # Look for similar folders or files
    folder_names = defaultdict(list)
    for file in files:
        parts = file['rel_path'].split('/')
        if len(parts) > 1:
            folder = parts[0]
            folder_names[folder].append(file)
    
    suspicious_folders = [
        'Views', 'Managers', 'Services', 'Models', 'ViewModels',
        'Features', 'Core', 'Data', 'API'
    ]
    
    for folder in sorted(folder_names.keys()):
        if folder in suspicious_folders:
            count = len(folder_names[folder])
            print(f"\n  {folder}/ - {count} files")
            if count > 30:
                print(f"      ⚠️  LARGE FOLDER - Consider breaking into subfolders")
    
    return {
        'duplicates': duplicates,
        'unused': unused_definitions,
        'empty': empty_files,
        'problematic': problematic
    }

def main():
    print("🔬 ADVANCED CODEBASE QUALITY ANALYSIS")
    issues = analyze_dead_code()
    
    print("\n\n" + "=" * 100)
    print("SUMMARY")
    print("=" * 100)
    print(f"  Duplicate definitions: {len(issues['duplicates'])}")
    print(f"  Unused definitions: {len(issues['unused'])}")
    print(f"  Empty/stub files: {len(issues['empty'])}")
    print(f"  Problematic files: {len(issues['problematic'])}")
    
    # Write detailed report
    with open('/Users/hectorgarcia/Desktop/LyoApp July/CODEBASE_ISSUES.md', 'w') as f:
        f.write("# Codebase Quality Analysis Report\n\n")
        
        f.write(f"## Summary\n")
        f.write(f"- Duplicate definitions: {len(issues['duplicates'])}\n")
        f.write(f"- Unused definitions: {len(issues['unused'])}\n")
        f.write(f"- Empty/stub files: {len(issues['empty'])}\n\n")
        
        f.write("## Detailed Findings\n\n")
        
        f.write("### Duplicate Definitions\n")
        for dup in issues['duplicates'][:10]:
            f.write(f"- **{dup['name']}** (x{dup['count']})\n")
            for file in dup['files']:
                f.write(f"  - {file}\n")
        
        f.write("\n### Empty Files\n")
        for empty in issues['empty']:
            f.write(f"- {empty['file']} ({empty['size']} bytes)\n")
    
    print(f"\n✅ Detailed report saved to: CODEBASE_ISSUES.md")

if __name__ == "__main__":
    main()

