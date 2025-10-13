require 'xcodeproj'

project_path = 'LyoApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the file reference with the wrong path
file_refs = project.files.select { |f| f.path&.include?('Services/Services/EnhancedCourseGenerationService') }

file_refs.each do |file_ref|
  puts "Found file with wrong path: #{file_ref.path}"
  # Fix the path
  file_ref.path = 'Services/EnhancedCourseGenerationService.swift'
  puts "Fixed to: #{file_ref.path}"
end

project.save

puts "✅ Fixed EnhancedCourseGenerationService.swift path in Xcode project"
