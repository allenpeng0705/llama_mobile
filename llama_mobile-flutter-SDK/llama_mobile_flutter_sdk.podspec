Pod::Spec.new do |s|
  s.name             = 'llama_mobile_flutter_sdk'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for LlamaMobile'
  s.description      = <<-DESC
A Flutter plugin for LlamaMobile that provides access to LLMs on mobile devices.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Use modular headers for Swift compatibility
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_EMIT_LOC_STRINGS' => 'YES'
  }

  # Add the xcframework
  s.vendored_frameworks = 'LlamaMobile/llama_mobile.xcframework'

  # Required frameworks
  s.frameworks = 'Metal', 'Accelerate'
  s.libraries = 'c++'

  # Swift version
  s.swift_version = '5.0'
end