require 'xcodeproj'

project_path = 'LyoApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find the Services group or create it
services_group = project.main_group['LyoApp']['Services'] || project.main_group['LyoApp'].new_group('Services')

# Add the file
file_ref = services_group.new_file('Services/EnhancedCourseGenerationService.swift')

# Add to build phase
target.source_build_phase.add_file_reference(file_ref)

project.save

puts "✅ Added EnhancedCourseGenerationService.swift to Xcode project"
