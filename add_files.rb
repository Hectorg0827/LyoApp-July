require 'xcodeproj'

# Define paths
project_path = '/Users/republicalatuya/Desktop/LyoApp July/LyoApp.xcodeproj'
target_name = 'LyoApp'
group_path = 'LyoApp/LearningHub'
absolute_group_path = '/Users/republicalatuya/Desktop/LyoApp July/LyoApp/LearningHub'


# Open the project
project = Xcodeproj::Project.open(project_path)

# Find the target
target = project.targets.find { |t| t.name == target_name }
unless target
  puts "Target #{target_name} not found."
  exit
end

# Find or create the group
group = project.main_group.find_subpath(group_path, true)

# Clear existing file references in the group to avoid duplicates
group.clear

# Add files to the group and target
source_files = Dir.glob("#{absolute_group_path}/**/*.swift")
source_files.each do |file_path|
  relative_path = file_path.sub('/Users/republicalatuya/Desktop/LyoApp July/', '')
  file_ref = group.new_file(relative_path)
  # Check if the file is already in the build phase
  unless target.source_build_phase.files_references.include?(file_ref)
    target.add_file_references([file_ref])
  end
end

# Save the project
project.save

puts "Added #{source_files.count} files to target #{target_name}."
