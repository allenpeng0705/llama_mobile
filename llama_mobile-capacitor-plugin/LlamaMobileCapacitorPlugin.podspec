require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'LlamaMobileCapacitorPlugin'
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = package['repository']['url']
  s.author = package['author']
  s.source = { :git => package['repository']['url'], :tag => s.version.to_s }
  s.source_files = 'ios/Sources/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.exclude_files = 'ios/Libraries/**/*.metal'
  s.ios.deployment_target = '15.0'
  s.dependency 'Capacitor'
  s.swift_version = '5.1'
  
  # Add llama_mobile framework
  s.vendored_frameworks = 'ios/Libraries/llama_mobile.xcframework'
  s.framework = 'Foundation'
  s.framework = 'Accelerate'
  s.library = 'c++'
  
  # Copy metal files from the framework to the app bundle
  s.preserve_paths = 'ios/Libraries/llama_mobile.xcframework/**/*.metallib', 'ios/Libraries/llama_mobile.xcframework/**/*.metal'
  
  # Add metallib files as resources (metal files are handled via script)
  s.resources = 'ios/Libraries/llama_mobile.xcframework/ios-arm64/llama_mobile.framework/ggml-llama.metallib', 'ios/Libraries/llama_mobile.xcframework/ios-arm64/llama_mobile.framework/ggml-llama-sim.metallib'
  
  # Add a script phase to copy metal files for both device and simulator
  s.script_phase = {
    :name => 'Copy Metal Files',
    :script => <<-EOS
      # Create a directory for metal files if it doesn't exist
      mkdir -p "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
      
      # Copy metallib files for device
      cp -f "${PODS_ROOT}/LlamaMobileCapacitorPlugin/ios/Libraries/llama_mobile.xcframework/ios-arm64/llama_mobile.framework/ggml-llama.metallib" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/"
      
      # Copy metallib files for simulator
      cp -f "${PODS_ROOT}/LlamaMobileCapacitorPlugin/ios/Libraries/llama_mobile.xcframework/ios-arm64-simulator/llama_mobile.framework/ggml-llama.metallib" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/"
      cp -f "${PODS_ROOT}/LlamaMobileCapacitorPlugin/ios/Libraries/llama_mobile.xcframework/ios-arm64/llama_mobile.framework/ggml-llama-sim.metallib" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/"
      
      # Copy metal source file as fallback
      cp -f "${PODS_ROOT}/LlamaMobileCapacitorPlugin/ios/Libraries/llama_mobile.xcframework/ios-arm64/llama_mobile.framework/ggml-metal.metal" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/"
      
      echo "Copied metal files to app bundle"
    EOS
  }
  
  # Add a build rule to prevent metal files from being compiled
  s.pod_target_xcconfig = {
    'METAL_FILES_FOLDER_PATH' => '$(SRCROOT)/$(PRODUCT_NAME).metal',
    'METAL_LIBRARY_OUTPUT_DIR' => '$(CONFIGURATION_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)',
    'DISABLE_METAL_COMPILATION' => 'YES'
  }
end
