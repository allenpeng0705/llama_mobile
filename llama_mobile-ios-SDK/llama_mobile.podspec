Pod::Spec.new do |s|
  s.name         = "llama_mobile"
  
  # Read version from llama_mobile_version.h
  version_header = File.read('../lib/llama_mobile_version.h')
  version_string = version_header.match(/\#define LLAMA_MOBILE_VERSION_STRING "([^"]+)"/)[1]
  s.version      = version_string
  
  s.summary      = "llama_mobile iOS SDK"
  s.description  = <<-DESC
                   llama_mobile iOS SDK provides a Swift wrapper around the llama_mobile C API for easy integration into iOS projects.
                   It includes both the XCFramework with native implementations and a Swift wrapper for a friendly API.
                   DESC

  s.homepage     = "https://github.com/yourusername/llama_mobile"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Your Name" => "your.email@example.com" }
  s.platform     = :ios, "15.0"
  s.source       = { :git => "https://github.com/yourusername/llama_mobile.git", :tag => s.version.to_s }

  # Specify the XCFramework
  s.vendored_frameworks = "llama_mobile.xcframework"

  # Specify Swift source files
  s.source_files = "Sources/LlamaMobile/**/*.swift"

  # Specify dependencies
  s.frameworks = "Accelerate", "Metal"
  s.libraries = "c++"

  # Specify Swift version
  s.swift_version = "5.0"

  # Specify header search paths if needed
  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '$(PODS_ROOT)/llama_mobile/llama_mobile.xcframework/ios-arm64/llama_mobile.framework/Headers $(PODS_ROOT)/llama_mobile/llama_mobile.xcframework/ios-arm64-simulator/llama_mobile.framework/Headers'
  }

end
