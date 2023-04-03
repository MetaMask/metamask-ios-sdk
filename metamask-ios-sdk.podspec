#
# Be sure to run `pod lib lint metamask-ios-sdk.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'metamask-ios-sdk'
  s.version          = '0.1.1'
  s.summary          = 'Enable users to easily connect with their MetaMask Mobile wallet.'
  s.swift_version    = '5.0'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
The iOS MetaMask SDK enables native iOS apps to interact with the Ethereum blockchain via the MetaMask Mobile wallet.
                       DESC

  s.homepage         = 'https://github.com/MetaMask/metamask-ios-sdk'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'Copyright ConsenSys Software Inc. 2022. All rights reserved.', :file => 'LICENSE' }
  s.author           = { 'MetaMask' => 'sdk@metamask.io' }
  s.source           = { :git => 'https://github.com/MetaMask/metamask-ios-sdk.git', :tag => s.version.to_s }

  s.ios.deployment_target = '14.0'
  s.source_files = 'Sources/metamask-ios-sdk/Classes/**/*'
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  
  # s.resource_bundles = {
  #   'metamask-ios-sdk' => ['metamask-ios-sdk/Assets/*.png']
  # }
  s.vendored_frameworks = 'Sources/metamask-ios-sdk/Frameworks/Ecies.xcframework'
  s.dependency 'Socket.IO-Client-Swift', '~> 16.0.1'
end
