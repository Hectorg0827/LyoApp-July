require 'xcodeproj'

# Define paths
project_path = '/Users/republicalatuya/Desktop/LyoApp July/LyoApp.xcodeproj'
target_name = 'LyoApp'
correct_parent_group_path = 'LyoApp'
group_to_recreate = 'LearningHub'
absolute_source_path = '/Users/republicalatuya/Desktop/LyoApp July/LyoApp/LearningHub'

# Open the project
project = Xcodeproj::Project.open(project_path)

# Find the target
target = project.targets.find { |t| t.name == target_name }
unless target
  puts "Target '#{target_name}' not found."
  exit
end

# Find and destroy the old group(s) to ensure a clean slate
puts "Searching for and destroying existing '#{group_to_recreate}' groups..."
project.main_group.recursive_children.each do |child|
  if child.is_a?(Xcodeproj::Project::Object::PBXGroup) && child.display_name == group_to_recreate
    puts "Found and removing group at path: #{child.real_path}"
    # Remove files within this group from the target
    child.files.each do |file|
      target.source_build_phase.remove_file_reference(file)
    end
    child.remove_from_project
  end
end

# Find the correct parent group
parent_group = project.main_group.find_subpath(correct_parent_group_path)
unless parent_group
  puts "Parent group '#{correct_parent_group_path}' not found."
  exit
end

# Create the new group
puts "Creating new '#{group_to_recreate}' group under '#{correct_parent_group_path}'."
new_group = parent_group.new_group(group_to_recreate, 'LyoApp/LearningHub')

# Add files to the new group and the target
puts "Adding source files from '#{absolute_source_path}'..."
source_files = Dir.glob("#{absolute_source_path}/**/*.swift")
file_references = source_files.map do |file_path|
  new_group.new_file(file_path)
end
target.add_file_references(file_references)

# Save the project
project.save

puts "Project structure for '#{group_to_recreate}' has been rebuilt. Added #{source_files.count} files."
