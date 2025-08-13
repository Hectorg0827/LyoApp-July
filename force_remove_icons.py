#!/usr/bin/env python3
import os
import glob

# Define the app icon directory
icon_dir = "/Users/republicalatuya/Desktop/LyoApp July/LyoApp/Assets.xcassets/AppIcon.appiconset"

# List of unwanted files (underscore pattern)
unwanted_files = [
    "icon_1024x1024.png",
    "icon_120x120.png", 
    "icon_152x152.png",
    "icon_167x167.png",
    "icon_180x180.png",
    "icon_20x20.png",
    "icon_29x29.png",
    "icon_40x40.png",
    "icon_58x58.png",
    "icon_60x60.png",
    "icon_76x76.png",
    "icon_80x80.png",
    "icon_87x87.png"
]

print("Current directory contents:")
for file in os.listdir(icon_dir):
    print(f"  {file}")

print("\nAttempting to remove unwanted files...")

removed_count = 0
for filename in unwanted_files:
    filepath = os.path.join(icon_dir, filename)
    if os.path.exists(filepath):
        try:
            os.remove(filepath)
            print(f"✓ Removed: {filename}")
            removed_count += 1
        except Exception as e:
            print(f"✗ Failed to remove {filename}: {e}")
    else:
        print(f"- File not found: {filename}")

print(f"\nRemoved {removed_count} files")

print("\nFinal directory contents:")
for file in os.listdir(icon_dir):
    print(f"  {file}")
