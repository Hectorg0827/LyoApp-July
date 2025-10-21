#!/bin/bash

PROJ_FILE="/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj/project.pbxproj"

# Create backup
cp "$PROJ_FILE" "${PROJ_FILE}.backup"

# Remove all lines that contain the duplicate 34416C* or 34416D* IDs in the files section
# This is a DESTRUCTIVE operation - removing all entries with these prefixes from the Compile Sources
sed -i '' '/^[[:space:]]*34416C[0-9A-F]*2EA33191007655C2 .*in Sources.*$/d' "$PROJ_FILE"
sed -i '' '/^[[:space:]]*34416D[0-9A-F]*2EA33191007655C2 .*in Sources.*$/d' "$PROJ_FILE"

echo "✅ Removed all duplicate 34416C* and 34416D* entries from Xcode project"
