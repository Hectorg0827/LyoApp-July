#!/bin/bash

# Unity Integration Script for LyoApp
# This script automates the integration of Unity iOS export into the LyoApp Xcode project

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR"
UNITY_EXPORT_PATH="${1:-/Users/hectorgarcia/Downloads/UnityClassroom_oct_15_iOS_Export}"
XCODE_PROJECT="$PROJECT_DIR/LyoApp.xcodeproj"
FRAMEWORKS_DIR="$PROJECT_DIR/Frameworks"
UNITY_DATA_TARGET="$PROJECT_DIR/LyoApp/UnityData"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          LyoApp Unity Integration Automation Script           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Check if Unity export exists
echo "📦 Step 1: Checking Unity export..."
if [ ! -d "$UNITY_EXPORT_PATH" ]; then
    echo "❌ Unity export not found at: $UNITY_EXPORT_PATH"
    echo ""
    echo "Please export your Unity project first:"
    echo "  1. Open Unity project: /Users/hectorgarcia/Downloads/UnityClassroom_oct 15"
    echo "  2. Go to File > Build Settings > iOS"
    echo "  3. Check 'Export Project'"
    echo "  4. Click 'Export' and save to: $UNITY_EXPORT_PATH"
    echo ""
    echo "Then run this script again:"
    echo "  ./integrate_unity.sh"
    exit 1
fi

# Step 2: Find UnityFramework.framework
echo "🔍 Step 2: Locating UnityFramework.framework..."
UNITY_FRAMEWORK=$(find "$UNITY_EXPORT_PATH" -name "UnityFramework.framework" -type d | head -n 1)

if [ -z "$UNITY_FRAMEWORK" ]; then
    echo "❌ UnityFramework.framework not found in export"
    echo "   Make sure you exported as iOS Library from Unity"
    exit 1
fi

echo "✅ Found: $UNITY_FRAMEWORK"

# Step 3: Find Data folder
echo "🔍 Step 3: Locating Unity Data folder..."
UNITY_DATA=$(find "$UNITY_EXPORT_PATH" -name "Data" -type d | head -n 1)

if [ -z "$UNITY_DATA" ]; then
    echo "❌ Unity Data folder not found in export"
    exit 1
fi

echo "✅ Found: $UNITY_DATA"

# Step 4: Create Frameworks directory
echo "📁 Step 4: Creating Frameworks directory..."
mkdir -p "$FRAMEWORKS_DIR"

# Step 5: Copy UnityFramework.framework
echo "📋 Step 5: Copying UnityFramework.framework..."
if [ -d "$FRAMEWORKS_DIR/UnityFramework.framework" ]; then
    echo "   Removing old framework..."
    rm -rf "$FRAMEWORKS_DIR/UnityFramework.framework"
fi

cp -R "$UNITY_FRAMEWORK" "$FRAMEWORKS_DIR/"
echo "✅ Framework copied to: $FRAMEWORKS_DIR/UnityFramework.framework"

# Step 6: Copy Unity Data folder
echo "📋 Step 6: Copying Unity Data folder..."
if [ -d "$UNITY_DATA_TARGET" ]; then
    echo "   Removing old Data folder..."
    rm -rf "$UNITY_DATA_TARGET"
fi

cp -R "$UNITY_DATA" "$UNITY_DATA_TARGET"
echo "✅ Data copied to: $UNITY_DATA_TARGET"

# Step 7: Update Xcode project
echo "🔧 Step 7: Updating Xcode project..."

PROJECT_DIR="$PROJECT_DIR" python3 << 'PYTHON_SCRIPT'
import sys
import os
import uuid
import re

project_dir = os.environ.get('PROJECT_DIR', '/Users/hectorgarcia/Desktop/LyoApp July')
pbxproj_path = os.path.join(project_dir, 'LyoApp.xcodeproj', 'project.pbxproj')

with open(pbxproj_path, 'r') as f:
    content = f.read()

# Check if UnityFramework already exists
if 'UnityFramework.framework' in content:
    print("   ℹ️  UnityFramework already in project, updating...")
    # Remove old references
    content = re.sub(r'[A-F0-9]{24} /\* UnityFramework\.framework[^;]*;', '', content)

# Generate UUIDs
framework_file_ref = uuid.uuid4().hex[:24].upper()
framework_build_file = uuid.uuid4().hex[:24].upper()
data_folder_ref = uuid.uuid4().hex[:24].upper()
data_build_file = uuid.uuid4().hex[:24].upper()

# Add framework file reference
file_ref_entry = f"""		{framework_file_ref} /* UnityFramework.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = UnityFramework.framework; path = Frameworks/UnityFramework.framework; sourceTree = "<group>"; }};
"""

# Add framework build file
build_file_entry = f"""		{framework_build_file} /* UnityFramework.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {framework_file_ref} /* UnityFramework.framework */; settings = {{ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }}; }};
"""

# Add Data folder reference
data_ref_entry = f"""		{data_folder_ref} /* UnityData */ = {{isa = PBXFileReference; lastKnownFileType = folder; path = UnityData; sourceTree = "<group>"; }};
"""

# Add Data build file
data_build_entry = f"""		{data_build_file} /* UnityData in Resources */ = {{isa = PBXBuildFile; fileRef = {data_folder_ref} /* UnityData */; }};
"""

# Insert into appropriate sections
pbx_build_file_marker = '/* Begin PBXBuildFile section */'
pbx_file_ref_marker = '/* Begin PBXFileReference section */'

build_insert_pos = content.find(pbx_build_file_marker) + len(pbx_build_file_marker)
content = content[:build_insert_pos] + "\n" + build_file_entry + data_build_entry + content[build_insert_pos:]

# Update positions after insertion
file_ref_insert_pos = content.find(pbx_file_ref_marker) + len(pbx_file_ref_marker)
content = content[:file_ref_insert_pos] + "\n" + file_ref_entry + data_ref_entry + content[file_ref_insert_pos:]

# Add to Frameworks build phase
frameworks_phase_pattern = r'(isa = PBXFrameworksBuildPhase;[^}]*files = \(\n)'
match = re.search(frameworks_phase_pattern, content, re.DOTALL)
if match:
    insert_pos = match.end()
    content = content[:insert_pos] + f"\t\t\t\t{framework_build_file} /* UnityFramework.framework in Frameworks */,\n" + content[insert_pos:]

# Add to Resources build phase
resources_phase_pattern = r'(isa = PBXResourcesBuildPhase;[^}]*files = \(\n)'
match = re.search(resources_phase_pattern, content, re.DOTALL)
if match:
    insert_pos = match.end()
    content = content[:insert_pos] + f"\t\t\t\t{data_build_file} /* UnityData in Resources */,\n" + content[insert_pos:]

# Add framework search paths
build_settings_pattern = r'(ENABLE_BITCODE = NO;)'
if re.search(build_settings_pattern, content):
    content = re.sub(
        build_settings_pattern,
        r'\1\n\t\t\t\tFRAMEWORK_SEARCH_PATHS = (\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t\t"$(PROJECT_DIR)/Frameworks",\n\t\t\t\t);',
        content,
        count=1
    )

with open(pbxproj_path, 'w') as f:
    f.write(content)

print("   ✅ Xcode project updated")
PYTHON_SCRIPT

# Step 8: Verify integration
echo ""
echo "🎉 Unity Integration Complete!"
echo ""
echo "Next steps:"
echo "  1. Open LyoApp.xcodeproj in Xcode"
echo "  2. Select LyoApp target > General tab"
echo "  3. Verify UnityFramework.framework is in 'Frameworks, Libraries, and Embedded Content'"
echo "  4. Ensure it's set to 'Embed & Sign'"
echo "  5. Build and run the project"
echo ""
echo "The UnityBridge in your app will automatically detect and initialize Unity!"
echo ""
