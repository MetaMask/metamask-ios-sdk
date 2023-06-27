Pod::Spec.new do |s|
  s.name             = 'metamask-ios-sdk'
  s.version          = '0.2.0'
  s.summary          = 'Enable users to easily connect with their MetaMask Mobile wallet.'
  s.swift_version    = '5.0'

  s.description      = <<-DESC
The iOS MetaMask SDK enables native iOS apps to interact with the Ethereum blockchain via the MetaMask Mobile wallet.
                       DESC

  s.homepage         = 'https://github.com/MetaMask/metamask-ios-sdk'
  s.license          = { :type => 'Copyright ConsenSys Software Inc. 2022. All rights reserved.', :file => 'LICENSE' }
  s.author           = { 'MetaMask' => 'sdk@metamask.io' }
  s.source           = { :git => 'https://github.com/MetaMask/metamask-ios-sdk.git', :tag => s.version.to_s }

  s.ios.deployment_target = '14.0'
  s.source_files = 'Sources/metamask-ios-sdk/Classes/**/*'
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  
  s.vendored_frameworks = 'Sources/metamask-ios-sdk/Frameworks/Ecies.xcframework'
  s.dependency 'Socket.IO-Client-Swift', '~> 16.0.1'
end
