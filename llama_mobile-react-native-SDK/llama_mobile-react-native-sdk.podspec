require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = package['name']
  s.version      = package['version']
  s.summary      = package['description']
  s.description  = <<-DESC
    React Native SDK for Llama Mobile
  DESC
  s.homepage     = package['homepage']
  s.license      = package['license']
  s.author       = package['author']
  s.platforms    = { :ios => "13.0" }
  s.source       = { :git => package['repository']['url'], :tag => "v#{s.version}" }
  s.source_files = "ios/Classes/**/*.{h,m,mm}"
  s.requires_arc = true
  
  s.dependency 'React-Core'
  
  # Reference the embedded llama_mobile framework
  s.source_files = "ios/Classes/**/*"
  s.vendored_frameworks = 'ios/Frameworks/llama_mobile.xcframework'
  
  # Add necessary frameworks for iOS
  s.frameworks = 'Foundation', 'Metal', 'MetalKit', 'Accelerate', 'AVFoundation', 'CoreGraphics', 'CoreImage', 'CoreML', 'CoreVideo'
  
  # Add necessary libraries
  s.libraries = 'c++', 'z', 'sqlite3', 'objc'
end
