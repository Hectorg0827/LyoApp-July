#!/usr/bin/env ruby
require 'xcodeproj'

# Script to add CourseBuilder files to Xcode project programmatically
# This is safer than manually editing project.pbxproj

project_path = '/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first
puts "📱 Target: #{target.name}"

# Find the main group (LyoApp)
main_group = project.main_group.find_subpath('LyoApp', true)

# Find or create Views and ViewModels groups
views_group = main_group.find_subpath('Views', true) || main_group.new_group('Views')
viewmodels_group = main_group.find_subpath('ViewModels', true) || main_group.new_group('ViewModels')

puts "\n📁 Found groups:"
puts "  Views: #{views_group.path}"
puts "  ViewModels: #{viewmodels_group.path}"

# Files to add
view_files = [
  'CourseBuilderView.swift',
  'CourseCreationView.swift',
  'CourseGeneratingView.swift',
  'CoursePreferencesView.swift',
  'CourseProgressDetailView.swift'
]

viewmodel_files = [
  'CourseBuilderCoordinator.swift'
]

puts "\n🔧 Adding files to project..."

# Add View files
view_files.each do |filename|
  file_path = "LyoApp/Views/#{filename}"
  
  # Check if file already exists in project
  existing_ref = views_group.files.find { |f| f.path == filename }
  
  if existing_ref
    puts "  ⚠️  #{filename} already in project"
  else
    # Add file reference to the group
    file_ref = views_group.new_file(file_path)
    
    # Add file to build phase
    target.source_build_phase.add_file_reference(file_ref)
    
    puts "  ✅ Added: #{filename}"
  end
end

# Add ViewModel files
viewmodel_files.each do |filename|
  file_path = "LyoApp/ViewModels/#{filename}"
  
  # Check if file already exists in project
  existing_ref = viewmodels_group.files.find { |f| f.path == filename }
  
  if existing_ref
    puts "  ⚠️  #{filename} already in project"
  else
    # Add file reference to the group
    file_ref = viewmodels_group.new_file(file_path)
    
    # Add file to build phase
    target.source_build_phase.add_file_reference(file_ref)
    
    puts "  ✅ Added: #{filename}"
  end
end

# Save the project
project.save

puts "\n💾 Project saved!"
puts "\n🎉 All files have been added to the Xcode project."
puts "\n📋 Next steps:"
puts "  1. Open Xcode"
puts "  2. You should see the new files in the Views and ViewModels folders"
puts "  3. Press ⌘ + B to build"
puts "  4. Run ./verify-files.sh to confirm"
