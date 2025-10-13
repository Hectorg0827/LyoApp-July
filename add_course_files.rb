#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'LyoApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find or create Models and Views groups
models_group = project.main_group['LyoApp']['Models'] || project.main_group['LyoApp'].new_group('Models')
views_group = project.main_group['LyoApp']['Views'] || project.main_group['LyoApp'].new_group('Views')
services_group = project.main_group['LyoApp']['Services'] || project.main_group['LyoApp'].new_group('Services')

# Files to add
files_to_add = [
  { path: 'LyoApp/Models/ContentModels.swift', group: models_group },
  { path: 'LyoApp/Models/CourseBuilderModels.swift', group: models_group },
  { path: 'LyoApp/Views/CourseBuilderFlowView.swift', group: views_group },
  { path: 'LyoApp/Views/CardRailViews.swift', group: views_group },
  { path: 'LyoApp/Services/CurationEngine.swift', group: services_group }
]

files_to_add.each do |file_info|
  file_path = file_info[:path]
  group = file_info[:group]
  filename = File.basename(file_path)
  
  # Remove if already exists
  existing = group.files.find { |f| f.path == filename || f.real_path.to_s.include?(filename) }
  if existing
    puts "🗑️  Removing existing reference: #{filename}"
    existing.remove_from_project
  end
  
  # Add fresh reference with just filename (group handles path)
  file_ref = group.new_file(file_path)
  target.add_file_references([file_ref])
  puts "✅ Added: #{file_path}"
end

project.save
puts "✨ Project updated successfully!"
