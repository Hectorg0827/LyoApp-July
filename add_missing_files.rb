#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'LyoApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'LyoApp' }
puts "📱 Target: #{target.name}"

# Find the ViewModels group
viewmodels_group = project.main_group.groups.find { |g| g.path == 'ViewModels' }
if viewmodels_group.nil?
  viewmodels_group = project.main_group.new_group('ViewModels', 'LyoApp/ViewModels')
end

# Find the Views group
views_group = project.main_group.groups.find { |g| g.path == 'Views' }
if views_group.nil?
  views_group = project.main_group.new_group('Views', 'LyoApp/Views')
end

# Add CourseBuilderCoordinator.swift to ViewModels
coordinator_path = 'LyoApp/ViewModels/CourseBuilderCoordinator.swift'
if File.exist?(coordinator_path)
  # Check if already exists
  existing = viewmodels_group.files.find { |f| f.path == 'CourseBuilderCoordinator.swift' }
  if existing.nil?
    file_ref = viewmodels_group.new_reference(coordinator_path)
    file_ref.source_tree = '<group>'
    target.source_build_phase.add_file_reference(file_ref)
    puts "✅ Added: CourseBuilderCoordinator.swift to ViewModels"
  else
    puts "⚠️  CourseBuilderCoordinator.swift already in ViewModels group"
  end
else
  puts "❌ File not found: #{coordinator_path}"
end

# Add CourseCreationView.swift to Views
creation_path = 'LyoApp/Views/CourseCreationView.swift'
if File.exist?(creation_path)
  # Check if already exists
  existing = views_group.files.find { |f| f.path == 'CourseCreationView.swift' }
  if existing.nil?
    file_ref = views_group.new_reference(creation_path)
    file_ref.source_tree = '<group>'
    target.source_build_phase.add_file_reference(file_ref)
    puts "✅ Added: CourseCreationView.swift to Views"
  else
    puts "⚠️  CourseCreationView.swift already in Views group"
  end
else
  puts "❌ File not found: #{creation_path}"
end

project.save
puts "💾 Project saved!"
