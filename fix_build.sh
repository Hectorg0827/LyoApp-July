#!/bin/bash
cd "/Users/republicalatuya/Desktop/LyoApp July"

# Rename DataManager.swift to avoid conflicts
mv LyoApp/Data/DataManager.swift LyoApp/Data/DataPersistenceManager.swift 2>/dev/null || echo "File already renamed or doesn't exist"

# Clean build artifacts
rm -rf ~/Library/Developer/Xcode/DerivedData/LyoApp*

# Regenerate project
xcodegen generate

echo "Build fix completed!"
