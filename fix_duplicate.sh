#!/bin/bash
# Remove the duplicate DataManager.swift file at root
if [ -f "LyoApp/DataManager.swift" ]; then
    echo "Removing duplicate DataManager.swift"
    rm "LyoApp/DataManager.swift"
fi

# Regenerate the project
xcodegen generate
