#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint llama_mobile_flutter_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'llama_mobile_flutter_sdk'
  s.version          = '0.0.1'
  s.summary          = 'Flutter SDK for llama_mobile.'
  s.description      = <<-DESC
Flutter SDK wrapper for llama_mobile iOS framework and Android library.
                       DESC
  s.homepage         = 'https://github.com/llama_mobile/llama_mobile'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'llama_mobile team' => 'contact@llama_mobile.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.vendored_frameworks = 'LlamaMobile/llama_mobile.xcframework'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.frameworks = 'Accelerate'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'llama_mobile_flutter_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
