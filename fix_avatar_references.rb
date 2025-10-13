#!/usr/bin/env ruby

# Clean fix for Avatar system files - removes ALL old references and adds correct ones
require 'xcodeproj'

project_path = 'LyoApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "🧹 Removing ALL Avatar-related references from project..."

# Find the main target
target = project.targets.first
puts "📱 Target: #{target.name}"

# Remove ALL Avatar file references from everywhere
files_to_remove = []
project.files.each do |file_ref|
  if file_ref.path && (file_ref.path.include?('AvatarModels.swift') || 
                       file_ref.path.include?('AvatarStore.swift') || 
                       file_ref.path.include?('QuickAvatarSetupView.swift'))
    puts "  ❌ Removing: #{file_ref.path}"
    files_to_remove << file_ref
  end
end

# Remove from build phases first
target.source_build_phase.files.each do |build_file|
  if build_file.file_ref && files_to_remove.include?(build_file.file_ref)
    build_file.remove_from_project
  end
end

# Remove file references
files_to_remove.each do |file_ref|
  file_ref.remove_from_project
end

puts "\n✅ Cleaned up #{files_to_remove.count} old references"

# Now add fresh references with correct paths
puts "\n📁 Adding fresh references..."

main_group = project.main_group['LyoApp']
if main_group.nil?
  puts "❌ Error: Could not find LyoApp group"
  exit 1
end

# Ensure groups exist
models_group = main_group['Models'] || main_group.new_group('Models', 'LyoApp/Models')
managers_group = main_group['Managers'] || main_group.new_group('Managers', 'LyoApp/Managers')

puts "  📂 Models group: #{models_group.path || models_group.name}"
puts "  📂 Managers group: #{managers_group.path || managers_group.name}"
puts "  📂 LyoApp group: #{main_group.path || main_group.name}"

# Add AvatarModels.swift - ABSOLUTE path from project root
avatar_models_file = File.expand_path('LyoApp/Models/AvatarModels.swift')
if File.exist?(avatar_models_file)
  # Use relative path from group's location
  file_ref = models_group.new_reference('AvatarModels.swift')
  file_ref.source_tree = '<group>'
  target.add_file_references([file_ref])
  puts "  ✅ Added: Models/AvatarModels.swift"
else
  puts "  ❌ File not found: #{avatar_models_file}"
end

# Add AvatarStore.swift - ABSOLUTE path from project root
avatar_store_file = File.expand_path('LyoApp/Managers/AvatarStore.swift')
if File.exist?(avatar_store_file)
  # Use relative path from group's location
  file_ref = managers_group.new_reference('AvatarStore.swift')
  file_ref.source_tree = '<group>'
  target.add_file_references([file_ref])
  puts "  ✅ Added: Managers/AvatarStore.swift"
else
  puts "  ❌ File not found: #{avatar_store_file}"
end

# Add QuickAvatarSetupView.swift - ABSOLUTE path from project root
quick_avatar_file = File.expand_path('LyoApp/QuickAvatarSetupView.swift')
if File.exist?(quick_avatar_file)
  # Use relative path from group's location
  file_ref = main_group.new_reference('QuickAvatarSetupView.swift')
  file_ref.source_tree = '<group>'
  target.add_file_references([file_ref])
  puts "  ✅ Added: LyoApp/QuickAvatarSetupView.swift"
else
  puts "  ❌ File not found: #{quick_avatar_file}"
end

# Save the project
project.save
puts "\n🎉 Project file updated successfully!"
puts "📝 Next: Build with Cmd+B or run the build task"
