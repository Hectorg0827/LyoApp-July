#!/usr/bin/env ruby

# Quick script to add Avatar system files to Xcode project
# Usage: ruby add_avatar_files.rb

require 'xcodeproj'

project_path = 'LyoApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.first

# Find or create group structure
main_group = project.main_group['LyoApp']
if main_group.nil?
  puts "❌ Error: Could not find LyoApp group"
  exit 1
end

# Find or create Models group
models_group = main_group['Models']
if models_group.nil?
  models_group = main_group.new_group('Models')
  puts "✅ Created Models group"
end

# Find or create Managers group
managers_group = main_group['Managers']
if managers_group.nil?
  managers_group = main_group.new_group('Managers')
  puts "✅ Created Managers group"
end

# Remove old references if they exist (cleanup)
puts "🧹 Cleaning up old references..."
target.source_build_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  if file_ref && (file_ref.path.include?('AvatarModels.swift') || 
                  file_ref.path.include?('AvatarStore.swift') || 
                  file_ref.path.include?('QuickAvatarSetupView.swift'))
    build_file.remove_from_project
    file_ref.remove_from_project
    puts "  Removed old reference: #{file_ref.path}"
  end
end

# Add AvatarModels.swift to Models group with correct relative path
avatar_models_path = 'Models/AvatarModels.swift'
if File.exist?("LyoApp/#{avatar_models_path}")
  file_ref = models_group.new_reference(avatar_models_path)
  target.add_file_references([file_ref])
  puts "✅ Added AvatarModels.swift to Models group"
else
  puts "❌ Error: LyoApp/#{avatar_models_path} not found"
end

# Add AvatarStore.swift to Managers group with correct relative path
avatar_store_path = 'Managers/AvatarStore.swift'
if File.exist?("LyoApp/#{avatar_store_path}")
  file_ref = managers_group.new_reference(avatar_store_path)
  target.add_file_references([file_ref])
  puts "✅ Added AvatarStore.swift to Managers group"
else
  puts "❌ Error: LyoApp/#{avatar_store_path} not found"
end

# Add QuickAvatarSetupView.swift to main LyoApp group with correct relative path
quick_avatar_path = 'QuickAvatarSetupView.swift'
if File.exist?("LyoApp/#{quick_avatar_path}")
  file_ref = main_group.new_reference(quick_avatar_path)
  target.add_file_references([file_ref])
  puts "✅ Added QuickAvatarSetupView.swift to LyoApp group"
else
  puts "❌ Error: LyoApp/#{quick_avatar_path} not found"
end

# Save the project
project.save
puts "\n🎉 Successfully added all Avatar system files to Xcode project!"
puts "📝 Next step: Build the project with Cmd+B or run:"
puts "   xcodebuild -project LyoApp.xcodeproj -scheme \"LyoApp 1\" build"
