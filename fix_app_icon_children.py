#!/usr/bin/env python3

import os
import json

def fix_app_icons():
    print("🧹 FIXING APP ICON UNASSIGNED CHILDREN ERROR")
    print("=" * 50)
    
    icon_dir = "/Users/republicalatuya/Desktop/LyoApp July/LyoApp/Assets.xcassets/AppIcon.appiconset"
    contents_json_path = os.path.join(icon_dir, "Contents.json")
    
    # Read Contents.json to see which files are actually referenced
    try:
        with open(contents_json_path, 'r') as f:
            contents = json.load(f)
        
        # Extract referenced filenames
        referenced_files = set()
        for image in contents.get('images', []):
            filename = image.get('filename')
            if filename:
                referenced_files.add(filename)
        
        print(f"📋 Files referenced in Contents.json: {len(referenced_files)}")
        for file in sorted(referenced_files):
            print(f"   ✅ {file}")
        
        # Find all PNG files in directory
        all_png_files = []
        for file in os.listdir(icon_dir):
            if file.endswith('.png'):
                all_png_files.append(file)
        
        print(f"\n📊 Total PNG files found: {len(all_png_files)}")
        
        # Find files to remove (exist but not referenced)
        files_to_remove = []
        for file in all_png_files:
            if file not in referenced_files:
                files_to_remove.append(file)
        
        print(f"\n🗑️  Files to remove (unassigned): {len(files_to_remove)}")
        
        # Remove unassigned files
        removed_count = 0
        for file in files_to_remove:
            file_path = os.path.join(icon_dir, file)
            try:
                os.remove(file_path)
                print(f"   ❌ Removed: {file}")
                removed_count += 1
            except Exception as e:
                print(f"   ⚠️  Failed to remove {file}: {e}")
        
        # Final verification
        final_png_files = [f for f in os.listdir(icon_dir) if f.endswith('.png')]
        print(f"\n✅ CLEANUP COMPLETE!")
        print(f"📊 Final PNG count: {len(final_png_files)}")
        print(f"🎯 Files removed: {removed_count}")
        
        if len(final_png_files) == len(referenced_files):
            print("🎉 SUCCESS: PNG files now match Contents.json references!")
            print("🚀 App icon unassigned children error should be resolved!")
        else:
            print("⚠️  Warning: File count mismatch may still exist")
            
        return len(final_png_files) == len(referenced_files)
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = fix_app_icons()
    exit(0 if success else 1)
