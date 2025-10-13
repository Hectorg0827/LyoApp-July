#!/usr/bin/env ruby

require 'xcodeproj'

# Path to the Xcode project
project_path = 'LyoApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Files to add (just filenames, they're in Services group already)
files_to_check = [
  'CourseProgressManager.swift',
  'LiveLearningOrchestrator.swift',
  'SentimentAwareAvatarManager.swift',
  'IntelligentMicroQuizManager.swift'
]

# Get Services group
services_group = project.main_group['LyoApp']['Services']

unless services_group
  puts "❌ Services group not found"
  exit 1
end

puts "📁 Found Services group"

files_to_check.each do |file_name|
  # Find all references to this file
  all_refs = project.files.select { |f| f.path == file_name || f.path.end_with?(file_name) }
  
  puts "\n🔍 Checking #{file_name}"
  puts "   Found #{all_refs.count} references"
  
  # Remove all existing references
  all_refs.each do |ref|
    puts "   Removing reference: #{ref.path}"
    # Remove from build phase
    target.source_build_phase.files.each do |build_file|
      if build_file.file_ref == ref
        target.source_build_phase.files.delete(build_file)
      end
    end
    # Remove from groups
    ref.parent&.children&.delete(ref)
  end
  
  # Check if file exists
  file_path = "LyoApp/Services/#{file_name}"
  unless File.exist?(file_path)
    puts "   ⚠️  File not found: #{file_path}"
    next
  end
  
  # Add new clean reference
  file_ref = services_group.new_file(file_path)
  target.source_build_phase.add_file_reference(file_ref)
  
  puts "   ✅ Added clean reference"
end

# Save project
project.save

puts "\n🎉 Project cleaned and updated!"
