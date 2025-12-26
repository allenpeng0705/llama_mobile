#!/usr/bin/env ruby
require 'xcodeproj'

# Project directory and name
project_dir = '/Users/shileipeng/Documents/mygithub/llama_mobile/examples/iOSFrameworkExample'
project_name = 'iOSFrameworkExample'
framework_dir = '/Users/shileipeng/Documents/mygithub/llama_mobile/llama_mobile-ios'
framework_path = "#{framework_dir}/llama_mobile.xcframework"

# Create the project
project = Xcodeproj::Project.new("#{project_dir}/#{project_name}.xcodeproj")

# Create the main target
target = project.new_target(:application, project_name, :ios, '13.0')
target.build_configurations.each do |config|
  config.build_settings['OTHER_LDFLAGS'] = ['-ObjC']
  config.build_settings['FRAMEWORK_SEARCH_PATHS'] = [framework_dir]
end

# Add files to the project
main_group = project.main_group
app_group = main_group.new_group(project_name)

# Add source files
files_to_add = [
  'AppDelegate.h',
  'AppDelegate.m',
  'ViewController.h',
  'ViewController.m',
  'Info.plist',
  'Assets.xcassets',
  'Base.lproj/Main.storyboard',
  'Base.lproj/LaunchScreen.storyboard'
]

files_to_add.each do |file|
  file_path = "#{project_dir}/#{project_name}/#{file}"
  if File.exist?(file_path)
    file_ref = app_group.new_reference(file_path)
    if file.end_with?('.m', '.swift')
      target.add_file_references([file_ref])
    elsif file.end_with?('.storyboard', '.xcassets')
      target.add_resources([file_ref])
    end
  end
end

# Add the xcframework
group = main_group.new_group('Frameworks')
framework_ref = group.new_file(framework_path)
target.frameworks_build_phase.add_file_reference(framework_ref)
target.add_system_frameworks(['UIKit', 'Foundation'])

# Save the project
project.save

puts "Xcode project created successfully at #{project_dir}/#{project_name}.xcodeproj"
puts "Framework added: #{framework_path}"