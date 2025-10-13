#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'LyoApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'LyoApp' }
puts "📱 Target: #{target.name}"

# First, remove any incorrect file references
files_to_clean = [
  'CourseBuilderCoordinator.swift',
  'CourseCreationView.swift'
]

files_to_clean.each do |filename|
  project.files.each do |file|
    if file.path&.include?(filename)
      # Check if path is duplicated
      if file.path.scan(/LyoApp/).count > 1
        puts "🗑️  Removing incorrect reference: #{file.path}"
        file.remove_from_project
      end
    end
  end
end

# Find the correct groups using display_name (not path)
viewmodels_group = nil
views_group = nil

def find_group_recursive(group, name)
  group.groups.each do |g|
    return g if g.display_name == name || g.path == name
    result = find_group_recursive(g, name)
    return result if result
  end
  nil
end

# Search for ViewModels and Views groups
project.main_group.groups.each do |group|
  if group.display_name == 'ViewModels' || group.path == 'ViewModels'
    viewmodels_group = group
  elsif group.display_name == 'Views' || group.path == 'Views'
    views_group = group
  end
  
  # Also check if they're in LyoApp subgroup
  if group.display_name == 'LyoApp' || group.path == 'LyoApp'
    group.groups.each do |subgroup|
      if subgroup.display_name == 'ViewModels' || subgroup.path == 'ViewModels'
        viewmodels_group = subgroup
      elsif subgroup.display_name == 'Views' || subgroup.path == 'Views'
        views_group = subgroup
      end
    end
  end
end

puts "📁 Found ViewModels group: #{viewmodels_group&.hierarchy_path || 'NOT FOUND'}"
puts "📁 Found Views group: #{views_group&.hierarchy_path || 'NOT FOUND'}"

# Add CourseBuilderCoordinator.swift
if viewmodels_group
  # Remove existing if any
  existing = viewmodels_group.files.find { |f| f.display_name == 'CourseBuilderCoordinator.swift' }
  existing&.remove_from_project
  
  # Add with simple reference
  file_ref = viewmodels_group.new_reference('CourseBuilderCoordinator.swift')
  file_ref.source_tree = '<group>'
  target.source_build_phase.add_file_reference(file_ref)
  puts "✅ Added: CourseBuilderCoordinator.swift"
else
  puts "❌ ViewModels group not found!"
end

# Add CourseCreationView.swift
if views_group
  # Remove existing if any
  existing = views_group.files.find { |f| f.display_name == 'CourseCreationView.swift' }
  existing&.remove_from_project
  
  # Add with simple reference
  file_ref = views_group.new_reference('CourseCreationView.swift')
  file_ref.source_tree = '<group>'
  target.source_build_phase.add_file_reference(file_ref)
  puts "✅ Added: CourseCreationView.swift"
else
  puts "❌ Views group not found!"
end

project.save
puts "💾 Project saved!"
