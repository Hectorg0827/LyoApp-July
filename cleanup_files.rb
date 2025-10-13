#!/usr/bin/env ruby
require 'xcodeproj'

# Script to fix CourseBuilder file paths in Xcode project

project_path = '/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
puts "📱 Target: #{target.name}"

# Files that were added with wrong paths
files_to_fix = [
  'CourseBuilderView.swift',
  'CourseCreationView.swift',
  'CourseGeneratingView.swift',
  'CoursePreferencesView.swift',
  'CourseProgressDetailView.swift',
  'CourseBuilderCoordinator.swift'
]

puts "\n🧹 Removing incorrectly added file references..."

# Remove all references to these files
removed_count = 0
project.files.each do |file_ref|
  if files_to_fix.any? { |f| file_ref.path&.include?(f) }
    puts "  🗑️  Removing: #{file_ref.path}"
    file_ref.remove_from_project
    removed_count += 1
  end
end

puts "\n✅ Removed #{removed_count} incorrect references"

# Save the project
project.save

puts "\n💾 Project saved!"
puts "\n📋 Now you need to add the files manually in Xcode with the correct settings."
puts "   Follow the instructions in QUICK_ADD_FILES.md"
