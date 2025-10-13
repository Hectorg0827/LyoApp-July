#!/usr/bin/env ruby

require 'xcodeproj'

# Path to the Xcode project
project_path = 'LyoApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Files to add
files_to_add = [
  'LyoApp/Services/CourseProgressManager.swift',
  'LyoApp/Services/LiveLearningOrchestrator.swift',
  'LyoApp/Services/SentimentAwareAvatarManager.swift',
  'LyoApp/Services/IntelligentMicroQuizManager.swift'
]

# Get or create Services group
services_group = project.main_group['LyoApp']['Services'] || project.main_group['LyoApp'].new_group('Services')

files_to_add.each do |file_path|
  # Check if file exists
  unless File.exist?(file_path)
    puts "⚠️  File not found: #{file_path}"
    next
  end
  
  # Check if already in project
  file_name = File.basename(file_path)
  existing_ref = services_group.files.find { |f| f.path == file_name }
  
  if existing_ref
    puts "✓ Already in project: #{file_name}"
    # Remove from build phase first
    target.source_build_phase.files.each do |build_file|
      if build_file.file_ref == existing_ref
        target.source_build_phase.files.delete(build_file)
      end
    end
    services_group.children.delete(existing_ref)
  end
  
  # Add file reference with just the filename
  file_ref = services_group.new_reference(file_name)
  file_ref.source_tree = '<group>'
  
  # Add to build phase
  target.source_build_phase.add_file_reference(file_ref)
  
  puts "✅ Added: #{file_name}"
end

# Save project
project.save

puts "\n🎉 Project updated successfully!"
puts "Now run: xcodebuild -project LyoApp.xcodeproj -scheme \"LyoApp 1\" build"
