require 'xcodeproj'

# Define paths
project_path = '/Users/republicalatuya/Desktop/LyoApp July/LyoApp.xcodeproj'
target_name = 'LyoApp'
group_path_to_fix = 'LyoApp/LearningHub'
absolute_source_path = '/Users/republicalatuya/Desktop/LyoApp July/LyoApp/LearningHub'

# Open the project
project = Xcodeproj::Project.open(project_path)

# Find the target
target = project.targets.find { |t| t.name == target_name }
unless target
  puts "Target '#{target_name}' not found."
  exit
end

# Find the group
group = project.main_group.find_subpath(group_path_to_fix)
unless group
  puts "Group '#{group_path_to_fix}' not found. Creating it."
  group = project.main_group.new_group('LearningHub', 'LyoApp/LearningHub')
end

# Remove all existing file references from the group and the target's build phase
puts "Clearing existing files from group '#{group_path_to_fix}'..."
group.files.each do |file|
  target.source_build_phase.remove_file_reference(file)
end
group.clear

# Add files from the directory to the group and target
puts "Adding source files from '#{absolute_source_path}'..."
source_files = Dir.glob("#{absolute_source_path}/**/*.swift")
file_references = source_files.map do |file|
  group.new_file(file)
end
target.add_file_references(file_references)

# Save the project
project.save

puts "Project updated. Re-added #{source_files.count} files to group '#{group_path_to_fix}' and target '#{target_name}'."
