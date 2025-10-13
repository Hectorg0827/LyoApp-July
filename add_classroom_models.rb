#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'LyoApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'LyoApp' }
puts "📱 Target: #{target.name}"

# Find the Models group
models_group = nil
project.main_group.groups.each do |group|
  if group.display_name == 'Models' || group.path == 'Models'
    models_group = group
  end
  
  # Also check if they're in LyoApp subgroup
  if group.display_name == 'LyoApp' || group.path == 'LyoApp'
    group.groups.each do |subgroup|
      if subgroup.display_name == 'Models' || subgroup.path == 'Models'
        models_group = subgroup
      end
    end
  end
end

puts "📁 Found Models group: #{models_group&.hierarchy_path || 'NOT FOUND'}"

# Add ClassroomModels.swift
if models_group
  # Remove existing if any
  existing = models_group.files.find { |f| f.display_name == 'ClassroomModels.swift' }
  existing&.remove_from_project
  
  # Add with simple reference
  file_ref = models_group.new_reference('ClassroomModels.swift')
  file_ref.source_tree = '<group>'
  target.source_build_phase.add_file_reference(file_ref)
  puts "✅ Added: ClassroomModels.swift"
else
  puts "❌ Models group not found!"
end

project.save
puts "💾 Project saved!"
