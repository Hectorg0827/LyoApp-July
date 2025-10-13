require 'xcodeproj'

project_path = 'LyoApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find all file references with Enhanced in the name
all_enhanced = project.files.select { |f| f.path&.include?('Enhanced') }

puts "Found #{all_enhanced.length} files with 'Enhanced' in path:"
all_enhanced.each do |f|
  puts "  - #{f.path}"
end

# Find the wrong one
wrong_files = project.files.select { |f| 
  f.path&.include?('EnhancedCourseGenerationService') && 
  (f.path.include?('Services/Services') || f.path.start_with?('Services/'))
}

puts "\nFiles to fix: #{wrong_files.length}"
wrong_files.each do |file_ref|
  old_path = file_ref.path
  puts "  Old: #{old_path}"
  
  # The actual file is in LyoApp/Services/
  file_ref.set_source_tree('SOURCE_ROOT')
  file_ref.set_path('LyoApp/Services/EnhancedCourseGenerationService.swift')
  
  puts "  New: #{file_ref.path}"
end

project.save
puts "\n✅ Fixed paths"
