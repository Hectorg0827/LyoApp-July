require 'xcodeproj'

project_path = 'LyoApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# Find all EnhancedCourseGenerationService references
all_refs = project.files.select { |f| f.path&.include?('EnhancedCourseGenerationService') }

puts "Found #{all_refs.length} file references for EnhancedCourseGenerationService"

# Get their UUIDs to find duplicates
ref_info = all_refs.map { |r| { uuid: r.uuid, path: r.path } }
ref_info.each { |info| puts "  UUID: #{info[:uuid]}, Path: #{info[:path]}" }

# Remove all from build phase
target.source_build_phase.files.each do |build_file|
  if build_file.file_ref&.path&.include?('EnhancedCourseGenerationService')
    puts "Removing from build phase: #{build_file.file_ref.path}"
    target.source_build_phase.remove_file_reference(build_file.file_ref)
  end
end

# Keep only the first reference, remove the rest
if all_refs.length > 1
  kept_ref = all_refs.first
  all_refs[1..-1].each do |dup_ref|
    puts "Removing duplicate: #{dup_ref.uuid}"
    dup_ref.remove_from_project
  end
  
  # Re-add the kept one to build phase
  target.source_build_phase.add_file_reference(kept_ref)
  puts "Re-added to build phase: #{kept_ref.path}"
end

project.save
puts "\n✅ Fixed duplicate references"
