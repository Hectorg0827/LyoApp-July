#!/bin/bash
# Simple script to verify files exist
echo "Checking Course Builder files..."
for file in \
  "LyoApp/Views/CourseBuilderView.swift" \
  "LyoApp/Views/TopicGatheringView.swift" \
  "LyoApp/Views/CoursePreferencesView.swift" \
  "LyoApp/Views/CourseGeneratingView.swift" \
  "LyoApp/Views/SyllabusPreviewView.swift" \
  "LyoApp/ViewModels/CourseBuilderCoordinator.swift"
do
  if [ -f "$file" ]; then
    echo "✅ $file exists"
  else
    echo "❌ $file NOT FOUND"
  fi
done
