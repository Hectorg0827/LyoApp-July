require 'xcodeproj'

project_path = 'LyoApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# Find or create the Services group
services_group = project.main_group['LyoApp']['Services']

if services_group.nil?
  puts "Services group not found, creating..."
  services_group = project.main_group['LyoApp'].new_group('Services', 'LyoApp/Services')
end

puts "Services group path: #{services_group.path}"

# Check if file already exists
existing = services_group.files.find { |f| f.path == 'EnhancedCourseGenerationService.swift' }

if existing
  puts "File reference already exists, removing..."
  existing.remove_from_project
end

# Add the file with SOURCE_ROOT source tree
file_ref = services_group.new_file('EnhancedCourseGenerationService.swift')
file_ref.set_source_tree('<group>')

puts "Added file reference: #{file_ref.path}"
puts "Real path from group: #{file_ref.real_path}"

# Add to build phase
target.source_build_phase.add_file_reference(file_ref)

puts "Added to build phase"

project.save

puts "\n✅ Successfully added EnhancedCourseGenerationService.swift"
